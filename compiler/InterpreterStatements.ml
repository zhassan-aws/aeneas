open Types
open TypesUtils
open Values
open ValuesUtils
open Expressions
open Contexts
open LlbcAst
open Cps
open InterpreterUtils
open InterpreterProjectors
open InterpreterExpansion
open InterpreterPaths
open InterpreterExpressions
module Subst = Substitute
module S = SynthesizeSymbolic

(** The local logger *)
let log = L.statements_log

(** Drop a value at a given place - TODO: factorize this with [assign_to_place] *)
let drop_value (config : config) (p : place) : cm_fun =
 fun cf ctx ->
  log#ldebug
    (lazy
      ("drop_value: place: " ^ place_to_string ctx p ^ "\n- Initial context:\n"
     ^ eval_ctx_to_string ctx));
  (* Note that we use [Write], not [Move]: we allow to drop values *below* borrows *)
  let access = Write in
  (* First make sure we can access the place, by ending loans or expanding
   * symbolic values along the path, for instance *)
  let cc = update_ctx_along_read_place config access p in
  (* Prepare the place (by ending the outer loans *at* the place). *)
  let cc = comp cc (prepare_lplace config p) in
  (* Replace the value with {!Bottom} *)
  let replace cf (v : typed_value) ctx =
    (* Move the value at destination (that we will overwrite) to a dummy variable
     * to preserve the borrows it may contain *)
    let mv = InterpreterPaths.read_place access p ctx in
    let dummy_id = fresh_dummy_var_id () in
    let ctx = ctx_push_dummy_var ctx dummy_id mv in
    (* Update the destination to ⊥ *)
    let nv = { v with value = VBottom } in
    let ctx = write_place access p nv ctx in
    log#ldebug
      (lazy
        ("drop_value: place: " ^ place_to_string ctx p ^ "\n- Final context:\n"
       ^ eval_ctx_to_string ctx));
    cf ctx
  in
  (* Compose and apply *)
  comp cc replace cf ctx

(** Push a dummy variable to the environment *)
let push_dummy_var (vid : DummyVarId.id) (v : typed_value) : cm_fun =
 fun cf ctx ->
  let ctx = ctx_push_dummy_var ctx vid v in
  cf ctx

(** Remove a dummy variable from the environment *)
let remove_dummy_var (vid : DummyVarId.id) (cf : typed_value -> m_fun) : m_fun =
 fun ctx ->
  let ctx, v = ctx_remove_dummy_var ctx vid in
  cf v ctx

(** Push an uninitialized variable to the environment *)
let push_uninitialized_var (var : var) : cm_fun =
 fun cf ctx ->
  let ctx = ctx_push_uninitialized_var ctx var in
  cf ctx

(** Push a list of uninitialized variables to the environment *)
let push_uninitialized_vars (vars : var list) : cm_fun =
 fun cf ctx ->
  let ctx = ctx_push_uninitialized_vars ctx vars in
  cf ctx

(** Push a variable to the environment *)
let push_var (var : var) (v : typed_value) : cm_fun =
 fun cf ctx ->
  let ctx = ctx_push_var ctx var v in
  cf ctx

(** Push a list of variables to the environment *)
let push_vars (vars : (var * typed_value) list) : cm_fun =
 fun cf ctx ->
  let ctx = ctx_push_vars ctx vars in
  cf ctx

(** Assign a value to a given place.

    Note that this function first pushes the value to assign in a dummy variable,
    then prepares the destination (by ending borrows, etc.) before popping the
    dummy variable and putting in its destination (after having checked that
    preparing the destination didn't introduce ⊥).
 *)
let assign_to_place (config : config) (rv : typed_value) (p : place) : cm_fun =
 fun cf ctx ->
  log#ldebug
    (lazy
      ("assign_to_place:" ^ "\n- rv: "
      ^ typed_value_to_string ctx rv
      ^ "\n- p: " ^ place_to_string ctx p ^ "\n- Initial context:\n"
      ^ eval_ctx_to_string ctx));
  (* Push the rvalue to a dummy variable, for bookkeeping *)
  let rvalue_vid = fresh_dummy_var_id () in
  let cc = push_dummy_var rvalue_vid rv in
  (* Prepare the destination *)
  let cc = comp cc (prepare_lplace config p) in
  (* Retrieve the rvalue from the dummy variable *)
  let cc = comp cc (fun cf _lv -> remove_dummy_var rvalue_vid cf) in
  (* Update the destination *)
  let move_dest cf (rv : typed_value) : m_fun =
   fun ctx ->
    (* Move the value at destination (that we will overwrite) to a dummy variable
     * to preserve the borrows *)
    let mv = InterpreterPaths.read_place Write p ctx in
    let dest_vid = fresh_dummy_var_id () in
    let ctx = ctx_push_dummy_var ctx dest_vid mv in
    (* Write to the destination *)
    (* Checks - maybe the bookkeeping updated the rvalue and introduced bottoms *)
    assert (not (bottom_in_value ctx.ended_regions rv));
    (* Update the destination *)
    let ctx = write_place Write p rv ctx in
    (* Debug *)
    log#ldebug
      (lazy
        ("assign_to_place:" ^ "\n- rv: "
        ^ typed_value_to_string ctx rv
        ^ "\n- p: " ^ place_to_string ctx p ^ "\n- Final context:\n"
        ^ eval_ctx_to_string ctx));
    (* Continue *)
    cf ctx
  in
  (* Compose and apply *)
  comp cc move_dest cf ctx

(** Evaluate an assertion, when the scrutinee is not symbolic *)
let eval_assertion_concrete (config : config) (assertion : assertion) :
    st_cm_fun =
 fun cf ctx ->
  (* There won't be any symbolic expansions: fully evaluate the operand *)
  let eval_op = eval_operand config assertion.cond in
  let eval_assert cf (v : typed_value) : m_fun =
   fun ctx ->
    match v.value with
    | VLiteral (VBool b) ->
        (* Branch *)
        if b = assertion.expected then cf Unit ctx else cf Panic ctx
    | _ ->
        raise
          (Failure ("Expected a boolean, got: " ^ typed_value_to_string ctx v))
  in
  (* Compose and apply *)
  comp eval_op eval_assert cf ctx

(** Evaluates an assertion.
    
    In the case the boolean under scrutinee is symbolic, we synthesize
    a call to [assert ...] then continue in the success branch (and thus
    expand the boolean to [true]).
 *)
let eval_assertion (config : config) (assertion : assertion) : st_cm_fun =
 fun cf ctx ->
  (* Evaluate the operand *)
  let eval_op = eval_operand config assertion.cond in
  (* Evaluate the assertion *)
  let eval_assert cf (v : typed_value) : m_fun =
   fun ctx ->
    assert (v.ty = TLiteral TBool);
    (* We make a choice here: we could completely decouple the concrete and
     * symbolic executions here but choose not to. In the case where we
     * know the concrete value of the boolean we test, we use this value
     * even if we are in symbolic mode. Note that this case should be
     * extremely rare... *)
    match v.value with
    | VLiteral (VBool _) ->
        (* Delegate to the concrete evaluation function *)
        eval_assertion_concrete config assertion cf ctx
    | VSymbolic sv ->
        assert (config.mode = SymbolicMode);
        assert (sv.sv_ty = TLiteral TBool);
        (* We continue the execution as if the test had succeeded, and thus
         * perform the symbolic expansion: sv ~~> true.
         * We will of course synthesize an assertion in the generated code
         * (see below). *)
        let ctx =
          apply_symbolic_expansion_non_borrow config sv (SeLiteral (VBool true))
            ctx
        in
        (* Continue *)
        let expr = cf Unit ctx in
        (* Add the synthesized assertion *)
        S.synthesize_assertion ctx v expr
    | _ ->
        raise
          (Failure ("Expected a boolean, got: " ^ typed_value_to_string ctx v))
  in
  (* Compose and apply *)
  comp eval_op eval_assert cf ctx

(** Updates the discriminant of a value at a given place.

    There are two situations:
    - either the discriminant is already the proper one (in which case we
      don't do anything)
    - or it is not the proper one (because the variant is not the proper
      one, or the value is actually {!Bottom} - this happens when
      initializing ADT values), in which case we replace the value with
      a variant with all its fields set to {!Bottom}.
      For instance, something like: [Cons Bottom Bottom].
 *)
let set_discriminant (config : config) (p : place) (variant_id : VariantId.id) :
    st_cm_fun =
 fun cf ctx ->
  log#ldebug
    (lazy
      ("set_discriminant:" ^ "\n- p: " ^ place_to_string ctx p
     ^ "\n- variant id: "
      ^ VariantId.to_string variant_id
      ^ "\n- initial context:\n" ^ eval_ctx_to_string ctx));
  (* Access the value *)
  let access = Write in
  let cc = update_ctx_along_read_place config access p in
  let cc = comp cc (prepare_lplace config p) in
  (* Update the value *)
  let update_value cf (v : typed_value) : m_fun =
   fun ctx ->
    match (v.ty, v.value) with
    | TAdt ((TAdtId _ as type_id), generics), VAdt av -> (
        (* There are two situations:
           - either the discriminant is already the proper one (in which case we
             don't do anything)
           - or it is not the proper one, in which case we replace the value with
             a variant with all its fields set to {!Bottom}
        *)
        match av.variant_id with
        | None -> raise (Failure "Found a struct value while expected an enum")
        | Some variant_id' ->
            if variant_id' = variant_id then (* Nothing to do *)
              cf Unit ctx
            else
              (* Replace the value *)
              let bottom_v =
                match type_id with
                | TAdtId def_id ->
                    compute_expanded_bottom_adt_value ctx def_id
                      (Some variant_id) generics
                | _ -> raise (Failure "Unreachable")
              in
              assign_to_place config bottom_v p (cf Unit) ctx)
    | TAdt ((TAdtId _ as type_id), generics), VBottom ->
        let bottom_v =
          match type_id with
          | TAdtId def_id ->
              compute_expanded_bottom_adt_value ctx def_id (Some variant_id)
                generics
          | _ -> raise (Failure "Unreachable")
        in
        assign_to_place config bottom_v p (cf Unit) ctx
    | _, VSymbolic _ ->
        assert (config.mode = SymbolicMode);
        (* This is a bit annoying: in theory we should expand the symbolic value
         * then set the discriminant, because in the case the discriminant is
         * exactly the one we set, the fields are left untouched, and in the
         * other cases they are set to Bottom.
         * For now, we forbid setting the discriminant of a symbolic value:
         * setting a discriminant should only be used to initialize a value,
         * or reset an already initialized value, really. *)
        raise (Failure "Unexpected value")
    | _, (VAdt _ | VBottom) -> raise (Failure "Inconsistent state")
    | _, (VLiteral _ | VBorrow _ | VLoan _) ->
        raise (Failure "Unexpected value")
  in
  (* Compose and apply *)
  comp cc update_value cf ctx

(** Push a frame delimiter in the context's environment *)
let ctx_push_frame (ctx : eval_ctx) : eval_ctx =
  { ctx with env = EFrame :: ctx.env }

(** Push a frame delimiter in the context's environment *)
let push_frame : cm_fun = fun cf ctx -> cf (ctx_push_frame ctx)

(** Small helper: compute the type of the return value for a specific
    instantiation of an assumed function.
 *)
let get_assumed_function_return_type (ctx : eval_ctx) (fid : assumed_fun_id)
    (generics : generic_args) : ety =
  assert (generics.trait_refs = []);
  (* [Box::free] has a special treatment *)
  match fid with
  | BoxFree ->
      assert (generics.regions = []);
      assert (List.length generics.types = 1);
      assert (generics.const_generics = []);
      mk_unit_ty
  | _ ->
      (* Retrieve the function's signature *)
      let sg = Assumed.get_assumed_fun_sig fid in
      (* Instantiate the return type  *)
      (* There shouldn't be any reference to Self *)
      let tr_self : trait_instance_id = UnknownTrait __FUNCTION__ in
      let generics = Subst.generic_args_erase_regions generics in
      let { Subst.r_subst = _; ty_subst; cg_subst; tr_subst; tr_self } =
        Subst.make_subst_from_generics sg.generics generics tr_self
      in
      let ty =
        Subst.erase_regions_substitute_types ty_subst cg_subst tr_subst tr_self
          sg.output
      in
      AssociatedTypes.ctx_normalize_erase_ty ctx ty

let move_return_value (config : config) (pop_return_value : bool)
    (cf : typed_value option -> m_fun) : m_fun =
 fun ctx ->
  if pop_return_value then
    let ret_vid = VarId.zero in
    let cc = eval_operand config (Move (mk_place_from_var_id ret_vid)) in
    cc (fun v ctx -> cf (Some v) ctx) ctx
  else cf None ctx

let pop_frame (config : config) (pop_return_value : bool)
    (cf : typed_value option -> m_fun) : m_fun =
 fun ctx ->
  (* Debug *)
  log#ldebug (lazy ("pop_frame:\n" ^ eval_ctx_to_string ctx));

  (* List the local variables, but the return variable *)
  let ret_vid = VarId.zero in
  let rec list_locals env =
    match env with
    | [] -> raise (Failure "Inconsistent environment")
    | EAbs _ :: env -> list_locals env
    | EBinding (BDummy _, _) :: env -> list_locals env
    | EBinding (BVar var, _) :: env ->
        let locals = list_locals env in
        if var.index <> ret_vid then var.index :: locals else locals
    | EFrame :: _ -> []
  in
  let locals : VarId.id list = list_locals ctx.env in
  (* Debug *)
  log#ldebug
    (lazy
      ("pop_frame: locals in which to drop the outer loans: ["
      ^ String.concat "," (List.map VarId.to_string locals)
      ^ "]"));

  (* Move the return value out of the return variable *)
  let cc = move_return_value config pop_return_value in
  (* Sanity check *)
  let cc =
    comp_check_value cc (fun ret_value ctx ->
        match ret_value with
        | None -> ()
        | Some ret_value ->
            assert (not (bottom_in_value ctx.ended_regions ret_value)))
  in

  (* Drop the outer *loans* we find in the local variables *)
  let cf_drop_loans_in_locals cf (ret_value : typed_value option) : m_fun =
    (* Drop the loans *)
    let locals = List.rev locals in
    let cf_drop =
      List.fold_left
        (fun cf lid ->
          drop_outer_loans_at_lplace config (mk_place_from_var_id lid) cf)
        (cf ret_value) locals
    in
    (* Apply *)
    cf_drop
  in
  let cc = comp cc cf_drop_loans_in_locals in
  (* Debug *)
  let cc =
    comp_check_value cc (fun _ ctx ->
        log#ldebug
          (lazy
            ("pop_frame: after dropping outer loans in local variables:\n"
           ^ eval_ctx_to_string ctx)))
  in

  (* Pop the frame - we remove the [Frame] delimiter, and reintroduce all
   * the local variables (which may still contain borrow permissions - but
   * no outer loans) as dummy variables in the caller frame *)
  let rec pop env =
    match env with
    | [] -> raise (Failure "Inconsistent environment")
    | EAbs abs :: env -> EAbs abs :: pop env
    | EBinding (_, v) :: env ->
        let vid = fresh_dummy_var_id () in
        EBinding (BDummy vid, v) :: pop env
    | EFrame :: env -> (* Stop here *) env
  in
  let cf_pop cf (ret_value : typed_value option) : m_fun =
   fun ctx ->
    let env = pop ctx.env in
    let ctx = { ctx with env } in
    cf ret_value ctx
  in
  (* Compose and apply *)
  comp cc cf_pop cf ctx

(** Pop the current frame and assign the returned value to its destination. *)
let pop_frame_assign (config : config) (dest : place) : cm_fun =
  let cf_pop = pop_frame config true in
  let cf_assign cf ret_value : m_fun =
    assign_to_place config (Option.get ret_value) dest cf
  in
  comp cf_pop cf_assign

(** Auxiliary function - see {!eval_assumed_function_call} *)
let eval_box_new_concrete (config : config) (generics : generic_args) : cm_fun =
 fun cf ctx ->
  (* Check and retrieve the arguments *)
  match
    (generics.regions, generics.types, generics.const_generics, ctx.env)
  with
  | ( [],
      [ boxed_ty ],
      [],
      EBinding (BVar input_var, input_value)
      :: EBinding (_ret_var, _)
      :: EFrame :: _ ) ->
      (* Required type checking *)
      assert (input_value.ty = boxed_ty);

      (* Move the input value *)
      let cf_move =
        eval_operand config (Move (mk_place_from_var_id input_var.index))
      in

      (* Create the new box *)
      let cf_create cf (moved_input_value : typed_value) : m_fun =
        (* Create the box value *)
        let generics = TypesUtils.mk_generic_args_from_types [ boxed_ty ] in
        let box_ty = TAdt (TAssumed TBox, generics) in
        let box_v =
          VAdt { variant_id = None; field_values = [ moved_input_value ] }
        in
        let box_v = mk_typed_value box_ty box_v in

        (* Move this value to the return variable *)
        let dest = mk_place_from_var_id VarId.zero in
        let cf_assign = assign_to_place config box_v dest in

        (* Continue *)
        cf_assign cf
      in

      (* Compose and apply *)
      comp cf_move cf_create cf ctx
  | _ -> raise (Failure "Inconsistent state")

(** Auxiliary function - see {!eval_assumed_function_call}.

    [Box::free] is not handled the same way as the other assumed functions:
    - in the regular case, whenever we need to evaluate an assumed function,
      we evaluate the operands, push a frame, call a dedicated function
      to correctly update the variables in the frame (and mimic the execution
      of a body) and finally pop the frame
    - in the case of [Box::free]: the value given to this function is often
      of the form [Box(⊥)] because we can move the value out of the
      box before freeing the box. It makes it invalid to see box_free as a
      "regular" function: it is not valid to call a function with arguments
      which contain [⊥]. For this reason, we execute [Box::free] as drop_value,
      but this is a bit annoying with regards to the semantics...

    Followingly this function doesn't behave like the others: it does not expect
    a stack frame to have been pushed, but rather simply behaves like {!drop_value}.
    It thus updates the box value (by calling {!drop_value}) and updates
    the destination (by setting it to [()]).
*)
let eval_box_free (config : config) (generics : generic_args)
    (args : operand list) (dest : place) : cm_fun =
 fun cf ctx ->
  match (generics.regions, generics.types, generics.const_generics, args) with
  | [], [ boxed_ty ], [], [ Move input_box_place ] ->
      (* Required type checking *)
      let input_box = InterpreterPaths.read_place Write input_box_place ctx in
      (let input_ty = ty_get_box input_box.ty in
       assert (input_ty = boxed_ty));

      (* Drop the value *)
      let cc = drop_value config input_box_place in

      (* Update the destination by setting it to [()] *)
      let cc = comp cc (assign_to_place config mk_unit_value dest) in

      (* Continue *)
      cc cf ctx
  | _ -> raise (Failure "Inconsistent state")

(** Evaluate a non-local function call in concrete mode *)
let eval_assumed_function_call_concrete (config : config) (fid : assumed_fun_id)
    (call : call) : cm_fun =
  let args = call.args in
  let dest = call.dest in
  match call.func with
  | FnOpMove _ ->
      (* Closure case: TODO *)
      raise (Failure "Closures are not supported yet")
  | FnOpRegular func -> (
      let generics = func.generics in
      (* Sanity check: we don't fully handle the const generic vars environment
         in concrete mode yet *)
      assert (generics.const_generics = []);
      (* There are two cases (and this is extremely annoying):
         - the function is not box_free
         - the function is box_free
         See {!eval_box_free}
      *)
      match fid with
      | BoxFree ->
          (* Degenerate case: box_free *)
          eval_box_free config generics args dest
      | _ ->
          (* "Normal" case: not box_free *)
          (* Evaluate the operands *)
          (*      let ctx, args_vl = eval_operands config ctx args in *)
          let cf_eval_ops = eval_operands config args in

          (* Evaluate the call
           *
           * Style note: at some point we used {!comp_transmit} to
           * transmit the result of {!eval_operands} above down to {!push_vars}
           * below, without having to introduce an intermediary function call,
           * but it made it less clear where the computed values came from,
           * so we reversed the modifications. *)
          let cf_eval_call cf (args_vl : typed_value list) : m_fun =
           fun ctx ->
            (* Push the stack frame: we initialize the frame with the return variable,
               and one variable per input argument *)
            let cc = push_frame in

            (* Create and push the return variable *)
            let ret_vid = VarId.zero in
            let ret_ty = get_assumed_function_return_type ctx fid generics in
            let ret_var = mk_var ret_vid (Some "@return") ret_ty in
            let cc = comp cc (push_uninitialized_var ret_var) in

            (* Create and push the input variables *)
            let input_vars =
              VarId.mapi_from1
                (fun id (v : typed_value) -> (mk_var id None v.ty, v))
                args_vl
            in
            let cc = comp cc (push_vars input_vars) in

            (* "Execute" the function body. As the functions are assumed, here we call
             * custom functions to perform the proper manipulations: we don't have
             * access to a body. *)
            let cf_eval_body : cm_fun =
              match fid with
              | BoxNew -> eval_box_new_concrete config generics
              | BoxFree ->
                  (* Should have been treated above *)
                  raise (Failure "Unreachable")
              | ArrayIndexShared | ArrayIndexMut | ArrayToSliceShared
              | ArrayToSliceMut | ArrayRepeat | SliceIndexShared | SliceIndexMut
                ->
                  raise (Failure "Unimplemented")
            in

            let cc = comp cc cf_eval_body in

            (* Pop the frame *)
            let cc = comp cc (pop_frame_assign config dest) in

            (* Continue *)
            cc cf ctx
          in
          (* Compose and apply *)
          comp cf_eval_ops cf_eval_call)

(** Helper
 
    Create abstractions (with no avalues, which have to be inserted afterwards)
    from a list of abs region groups.
    
    [region_can_end]: gives the region groups from which we generate functions
    which can end or not.
 *)
let create_empty_abstractions_from_abs_region_groups
    (kind : RegionGroupId.id -> abs_kind) (rgl : abs_region_group list)
    (region_can_end : RegionGroupId.id -> bool) : abs list =
  (* We use a reference to progressively create a map from abstraction ids
   * to set of ancestor regions. Note that {!abs_to_ancestors_regions} [abs_id]
   * returns the union of:
   * - the regions of the ancestors of abs_id
   * - the regions of abs_id
   *)
  let abs_to_ancestors_regions : RegionId.Set.t AbstractionId.Map.t ref =
    ref AbstractionId.Map.empty
  in
  (* Auxiliary function to create one abstraction *)
  let create_abs (rg_id : RegionGroupId.id) (rg : abs_region_group) : abs =
    let abs_id = rg.id in
    let original_parents = rg.parents in
    let parents =
      List.fold_left
        (fun s pid -> AbstractionId.Set.add pid s)
        AbstractionId.Set.empty rg.parents
    in
    let regions =
      List.fold_left
        (fun s rid -> RegionId.Set.add rid s)
        RegionId.Set.empty rg.regions
    in
    let ancestors_regions =
      List.fold_left
        (fun acc parent_id ->
          RegionId.Set.union acc
            (AbstractionId.Map.find parent_id !abs_to_ancestors_regions))
        RegionId.Set.empty rg.parents
    in
    let ancestors_regions_union_current_regions =
      RegionId.Set.union ancestors_regions regions
    in
    let can_end = region_can_end rg_id in
    abs_to_ancestors_regions :=
      AbstractionId.Map.add abs_id ancestors_regions_union_current_regions
        !abs_to_ancestors_regions;
    (* Create the abstraction *)
    {
      abs_id;
      kind = kind rg_id;
      can_end;
      parents;
      original_parents;
      regions;
      ancestors_regions;
      avalues = [];
    }
  in
  (* Apply *)
  RegionGroupId.mapi create_abs rgl

let create_push_abstractions_from_abs_region_groups
    (kind : RegionGroupId.id -> abs_kind) (rgl : abs_region_group list)
    (region_can_end : RegionGroupId.id -> bool)
    (compute_abs_avalues : abs -> eval_ctx -> eval_ctx * typed_avalue list)
    (ctx : eval_ctx) : eval_ctx =
  (* Initialize the abstractions as empty (i.e., with no avalues) abstractions *)
  let empty_absl =
    create_empty_abstractions_from_abs_region_groups kind rgl region_can_end
  in

  (* Compute and add the avalues to the abstractions, the insert the abstractions
   * in the context. *)
  let insert_abs (ctx : eval_ctx) (abs : abs) : eval_ctx =
    (* Compute the values to insert in the abstraction *)
    let ctx, avalues = compute_abs_avalues abs ctx in
    (* Add the avalues to the abstraction *)
    let abs = { abs with avalues } in
    (* Insert the abstraction in the context *)
    let ctx = { ctx with env = EAbs abs :: ctx.env } in
    (* Return *)
    ctx
  in
  List.fold_left insert_abs ctx empty_absl

(** Auxiliary helper for [eval_transparent_function_call_symbolic]
    Instantiate the signature and introduce fresh abstractions and region ids while doing so.

    We perform some manipulations when instantiating the signature.

    # Trait impl calls
    ==================
    In particular, we have a special treatment of trait method calls when
    the trait ref is a known impl.

    For instance:
    {[
      trait HasValue {
        fn has_value(&self) -> bool;
      }

      impl<T> HasValue for Option<T> {
        fn has_value(&self) {
          match self {
            None => false,
            Some(_) => true,
          }
        }
      }

      fn option_has_value<T>(x: &Option<T>) -> bool {
        x.has_value()
      }
    ]}

    The generated code looks like this:
    {[
      structure HasValue (Self : Type) = {
        has_value : Self -> result bool
      }

      let OptionHasValueImpl.has_value (Self : Type) (self : Self) : result bool =
        match self with
        | None => false
        | Some _ => true

      let OptionHasValueInstance (T : Type) : HasValue (Option T) = {
        has_value = OptionHasValueInstance.has_value
      }
    ]}

    In [option_has_value], we don't want to refer to the [has_value] method
    of the instance of [HasValue] for [Option<T>]. We want to refer directly
    to the function which implements [has_value] for [Option<T>].
    That is, instead of generating this:
    {[
      let option_has_value (T : Type) (x : Option T) : result bool =
        (OptionHasValueInstance T).has_value x
    ]}

    We want to generate this:
    {[
      let option_has_value (T : Type) (x : Option T) : result bool =
        OptionHasValueImpl.has_value T x
    ]}

    # Provided trait methods
    ========================
    Calls to provided trait methods also have a special treatment because
    for now we forbid overriding provided trait methods in the trait implementations,
    which means that whenever we call a provided trait method, we do not refer
    to a trait clause but directly to the method provided in the trait declaration.
 *)
let eval_transparent_function_call_symbolic_inst (call : call) (ctx : eval_ctx)
    :
    fun_id_or_trait_method_ref
    * generic_args
    * (generic_args * trait_instance_id) option
    * fun_decl
    * region_var_groups
    * inst_fun_sig =
  match call.func with
  | FnOpMove _ ->
      (* Closure case: TODO *)
      raise (Failure "Closures are not supported yet")
  | FnOpRegular func -> (
      match func.func with
      | FunId (FRegular fid) ->
          let def = ctx_lookup_fun_decl ctx fid in
          log#ldebug
            (lazy
              ("fun call:\n- call: " ^ call_to_string ctx call
             ^ "\n- call.generics:\n"
              ^ generic_args_to_string ctx func.generics
              ^ "\n- def.signature:\n"
              ^ fun_sig_to_string ctx def.signature));
          let tr_self = UnknownTrait __FUNCTION__ in
          let regions_hierarchy =
            LlbcAstUtils.FunIdMap.find (FRegular fid)
              ctx.fun_ctx.regions_hierarchies
          in
          let inst_sg =
            instantiate_fun_sig ctx func.generics tr_self def.signature
              regions_hierarchy
          in
          (func.func, func.generics, None, def, regions_hierarchy, inst_sg)
      | FunId (FAssumed _) ->
          (* Unreachable: must be a transparent function *)
          raise (Failure "Unreachable")
      | TraitMethod (trait_ref, method_name, _) -> (
          log#ldebug
            (lazy
              ("trait method call:\n- call: " ^ call_to_string ctx call
             ^ "\n- method name: " ^ method_name ^ "\n- call.generics:\n"
              ^ generic_args_to_string ctx func.generics
              ^ "\n- trait and method generics:\n"
              ^ generic_args_to_string ctx
                  (Option.get func.trait_and_method_generic_args)));
          (* When instantiating, we need to group the generics for the trait ref
             and the method *)
          let generics = Option.get func.trait_and_method_generic_args in
          (* Lookup the trait method signature - there are several possibilities
             depending on whethere we call a top-level trait method impl or the
             method from a local clause *)
          match trait_ref.trait_id with
          | TraitImpl impl_id -> (
              (* Lookup the trait impl *)
              let trait_impl = ctx_lookup_trait_impl ctx impl_id in
              log#ldebug
                (lazy ("trait impl: " ^ trait_impl_to_string ctx trait_impl));
              (* First look in the required methods *)
              let method_id =
                List.find_opt
                  (fun (s, _) -> s = method_name)
                  trait_impl.required_methods
              in
              match method_id with
              | Some (_, id) ->
                  (* This is a required method *)
                  let method_def = ctx_lookup_fun_decl ctx id in
                  (* Instantiate *)
                  let tr_self = TraitRef trait_ref in
                  let fid : fun_id = FRegular id in
                  let regions_hierarchy =
                    LlbcAstUtils.FunIdMap.find fid
                      ctx.fun_ctx.regions_hierarchies
                  in
                  let inst_sg =
                    instantiate_fun_sig ctx generics tr_self
                      method_def.signature regions_hierarchy
                  in
                  (* Also update the function identifier: we want to forget
                     the fact that we called a trait method, and treat it as
                     a regular function call to the top-level function
                     which implements the method. In order to do this properly,
                     we also need to update the generics.
                  *)
                  let func = FunId fid in
                  ( func,
                    generics,
                    Some (generics, tr_self),
                    method_def,
                    regions_hierarchy,
                    inst_sg )
              | None ->
                  (* If not found, lookup the methods provided by the trait *declaration*
                     (remember: for now, we forbid overriding provided methods) *)
                  assert (trait_impl.provided_methods = []);
                  let trait_decl =
                    ctx_lookup_trait_decl ctx
                      trait_ref.trait_decl_ref.trait_decl_id
                  in
                  let _, method_id =
                    List.find
                      (fun (s, _) -> s = method_name)
                      trait_decl.provided_methods
                  in
                  let method_id = Option.get method_id in
                  let method_def = ctx_lookup_fun_decl ctx method_id in
                  (* For the instantiation we have to do something peculiar
                     because the method was defined for the trait declaration.
                     We have to group:
                     - the parameters given to the trait decl reference
                     - the parameters given to the method itself
                     For instance:
                     {[
                       trait Foo<T> {
                         fn f<U>(...) { ... }
                       }

                       fn g<G>(x : G) where Clause0: Foo<G, bool>
                       {
                         x.f::<u32>(...) // The arguments to f are: <G, bool, u32>
                       }
                     ]}
                  *)
                  let all_generics =
                    TypesUtils.merge_generic_args
                      trait_ref.trait_decl_ref.decl_generics func.generics
                  in
                  log#ldebug
                    (lazy
                      ("provided method call:" ^ "\n- method name: "
                     ^ method_name ^ "\n- all_generics:\n"
                      ^ generic_args_to_string ctx all_generics
                      ^ "\n- parent params info: "
                      ^ Print.option_to_string show_params_info
                          method_def.signature.parent_params_info));
                  let regions_hierarchy =
                    LlbcAstUtils.FunIdMap.find (FRegular method_id)
                      ctx.fun_ctx.regions_hierarchies
                  in
                  let tr_self = TraitRef trait_ref in
                  let inst_sg =
                    instantiate_fun_sig ctx all_generics tr_self
                      method_def.signature regions_hierarchy
                  in
                  ( func.func,
                    func.generics,
                    Some (all_generics, tr_self),
                    method_def,
                    regions_hierarchy,
                    inst_sg ))
          | _ ->
              (* We are using a local clause - we lookup the trait decl *)
              let trait_decl =
                ctx_lookup_trait_decl ctx trait_ref.trait_decl_ref.trait_decl_id
              in
              (* Lookup the method decl in the required *and* the provided methods *)
              let _, method_id =
                let provided =
                  List.filter_map
                    (fun (id, f) ->
                      match f with None -> None | Some f -> Some (id, f))
                    trait_decl.provided_methods
                in
                List.find
                  (fun (s, _) -> s = method_name)
                  (List.append trait_decl.required_methods provided)
              in
              let method_def = ctx_lookup_fun_decl ctx method_id in
              log#ldebug
                (lazy ("method:\n" ^ fun_decl_to_string ctx method_def));
              (* Instantiate *)
              let regions_hierarchy =
                LlbcAstUtils.FunIdMap.find (FRegular method_id)
                  ctx.fun_ctx.regions_hierarchies
              in
              let tr_self = TraitRef trait_ref in
              let inst_sg =
                instantiate_fun_sig ctx generics tr_self method_def.signature
                  regions_hierarchy
              in
              ( func.func,
                func.generics,
                Some (generics, tr_self),
                method_def,
                regions_hierarchy,
                inst_sg )))

(** Evaluate a statement *)
let rec eval_statement (config : config) (st : statement) : st_cm_fun =
 fun cf ctx ->
  (* Debugging *)
  log#ldebug
    (lazy
      ("\n**About to evaluate statement**: [\n"
      ^ statement_to_string_with_tab ctx st
      ^ "\n]\n\n**Context**:\n" ^ eval_ctx_to_string ctx ^ "\n\n"));

  (* Expand the symbolic values if necessary - we need to do that before
   * checking the invariants *)
  let cc = greedy_expand_symbolic_values config in
  (* Sanity check *)
  let cc = comp cc Invariants.cf_check_invariants in

  (* Evaluate *)
  let cf_eval_st cf : m_fun =
   fun ctx ->
    match st.content with
    | Assign (p, rvalue) -> (
        (* We handle global assignments separately *)
        match rvalue with
        | Global gid ->
            (* Evaluate the global *)
            eval_global config p gid cf ctx
        | _ ->
            (* Evaluate the rvalue *)
            let cf_eval_rvalue = eval_rvalue_not_global config rvalue in
            (* Assign *)
            let cf_assign cf (res : (typed_value, eval_error) result) ctx =
              log#ldebug
                (lazy
                  ("about to assign to place: " ^ place_to_string ctx p
                 ^ "\n- Context:\n" ^ eval_ctx_to_string ctx));
              match res with
              | Error EPanic -> cf Panic ctx
              | Ok rv -> (
                  let expr = assign_to_place config rv p (cf Unit) ctx in
                  (* Update the synthesized AST - here we store meta-information.
                   * We do it only in specific cases (it is not always useful, and
                   * also it can lead to issues - for instance, if we borrow a
                   * reserved borrow, we later can't translate it to pure values...) *)
                  match rvalue with
                  | Global _ -> raise (Failure "Unreachable")
                  | Use _
                  | RvRef (_, (BShared | BMut | BTwoPhaseMut | BShallow))
                  | UnaryOp _ | BinaryOp _ | Discriminant _ | Aggregate _ ->
                      let rp = rvalue_get_place rvalue in
                      let rp =
                        match rp with
                        | Some rp -> Some (S.mk_mplace rp ctx)
                        | None -> None
                      in
                      S.synthesize_assignment ctx (S.mk_mplace p ctx) rv rp expr
                  )
            in

            (* Compose and apply *)
            comp cf_eval_rvalue cf_assign cf ctx)
    | FakeRead p -> eval_fake_read config p (cf Unit) ctx
    | SetDiscriminant (p, variant_id) ->
        set_discriminant config p variant_id cf ctx
    | Drop p -> drop_value config p (cf Unit) ctx
    | Assert assertion -> eval_assertion config assertion cf ctx
    | Call call -> eval_function_call config call cf ctx
    | Panic -> cf Panic ctx
    | Return -> cf Return ctx
    | Break i -> cf (Break i) ctx
    | Continue i -> cf (Continue i) ctx
    | Nop -> cf Unit ctx
    | Sequence (st1, st2) ->
        (* Evaluate the first statement *)
        let cf_st1 = eval_statement config st1 in
        (* Evaluate the sequence *)
        let cf_st2 cf res =
          match res with
          (* Evaluation successful: evaluate the second statement *)
          | Unit -> eval_statement config st2 cf
          (* Control-flow break: transmit. We enumerate the cases on purpose *)
          | Panic | Break _ | Continue _ | Return | LoopReturn _
          | EndEnterLoop _ | EndContinue _ ->
              cf res
        in
        (* Compose and apply *)
        comp cf_st1 cf_st2 cf ctx
    | Loop loop_body ->
        InterpreterLoops.eval_loop config st.meta
          (eval_statement config loop_body)
          cf ctx
    | Switch switch -> eval_switch config switch cf ctx
  in
  (* Compose and apply *)
  comp cc cf_eval_st cf ctx

and eval_global (config : config) (dest : place) (gid : GlobalDeclId.id) :
    st_cm_fun =
 fun cf ctx ->
  let global = ctx_lookup_global_decl ctx gid in
  match config.mode with
  | ConcreteMode ->
      (* Treat the evaluation of the global as a call to the global body (without arguments) *)
      let func =
        {
          func = FunId (FRegular global.body);
          generics = TypesUtils.empty_generic_args;
          trait_and_method_generic_args = None;
        }
      in
      let call = { func = FnOpRegular func; args = []; dest } in
      (eval_transparent_function_call_concrete config global.body call) cf ctx
  | SymbolicMode ->
      (* Generate a fresh symbolic value. In the translation, this fresh symbolic value will be
       * defined as equal to the value of the global (see {!S.synthesize_global_eval}). *)
      assert (ty_no_regions global.ty);
      let sval = mk_fresh_symbolic_value global.ty in
      let cc =
        assign_to_place config (mk_typed_value_from_symbolic_value sval) dest
      in
      let e = cc (cf Unit) ctx in
      S.synthesize_global_eval gid sval e

(** Evaluate a switch *)
and eval_switch (config : config) (switch : switch) : st_cm_fun =
 fun cf ctx ->
  (* We evaluate the operand in two steps:
   * first we prepare it, then we check if its value is concrete or
   * symbolic. If it is concrete, we can then evaluate the operand
   * directly, otherwise we must first expand the value.
   * Note that we can't fully evaluate the operand *then* expand the
   * value if it is symbolic, because the value may have been move
   * (and would thus floating in thin air...)!
   * *)
  (* Match on the targets *)
  let cf_match : st_cm_fun =
   fun cf ctx ->
    match switch with
    | If (op, st1, st2) ->
        (* Evaluate the operand *)
        let cf_eval_op = eval_operand config op in
        (* Switch on the value *)
        let cf_if (cf : st_m_fun) (op_v : typed_value) : m_fun =
         fun ctx ->
          match op_v.value with
          | VLiteral (VBool b) ->
              (* Evaluate the if and the branch body *)
              let cf_branch cf : m_fun =
                (* Branch *)
                if b then eval_statement config st1 cf
                else eval_statement config st2 cf
              in
              (* Compose the continuations *)
              cf_branch cf ctx
          | VSymbolic sv ->
              (* Expand the symbolic boolean, and continue by evaluating
               * the branches *)
              let cf_true : st_cm_fun = eval_statement config st1 in
              let cf_false : st_cm_fun = eval_statement config st2 in
              expand_symbolic_bool config sv
                (S.mk_opt_place_from_op op ctx)
                cf_true cf_false cf ctx
          | _ -> raise (Failure "Inconsistent state")
        in
        (* Compose *)
        comp cf_eval_op cf_if cf ctx
    | SwitchInt (op, int_ty, stgts, otherwise) ->
        (* Evaluate the operand *)
        let cf_eval_op = eval_operand config op in
        (* Switch on the value *)
        let cf_switch (cf : st_m_fun) (op_v : typed_value) : m_fun =
         fun ctx ->
          match op_v.value with
          | VLiteral (VScalar sv) ->
              (* Evaluate the branch *)
              let cf_eval_branch cf =
                (* Sanity check *)
                assert (sv.int_ty = int_ty);
                (* Find the branch *)
                match List.find_opt (fun (svl, _) -> List.mem sv svl) stgts with
                | None -> eval_statement config otherwise cf
                | Some (_, tgt) -> eval_statement config tgt cf
              in
              (* Compose *)
              cf_eval_branch cf ctx
          | VSymbolic sv ->
              (* Expand the symbolic value and continue by evaluating the
               * proper branches *)
              let stgts =
                List.map
                  (fun (cv, tgt_st) -> (cv, eval_statement config tgt_st))
                  stgts
              in
              (* Several branches may be grouped together: every branch is described
               * by a pair (list of values, branch expression).
               * In order to do a symbolic evaluation, we make this "flat" by
               * de-grouping the branches. *)
              let stgts =
                List.concat
                  (List.map
                     (fun (vl, st) -> List.map (fun v -> (v, st)) vl)
                     stgts)
              in
              (* Translate the otherwise branch *)
              let otherwise = eval_statement config otherwise in
              (* Expand and continue *)
              expand_symbolic_int config sv
                (S.mk_opt_place_from_op op ctx)
                int_ty stgts otherwise cf ctx
          | _ -> raise (Failure "Inconsistent state")
        in
        (* Compose *)
        comp cf_eval_op cf_switch cf ctx
    | Match (p, stgts, otherwise) ->
        (* Access the place *)
        let access = Read in
        let expand_prim_copy = false in
        let cf_read_p cf : m_fun =
          access_rplace_reorganize_and_read config expand_prim_copy access p cf
        in
        (* Match on the value *)
        let cf_match (cf : st_m_fun) (p_v : typed_value) : m_fun =
         fun ctx ->
          (* The value may be shared: we need to ignore the shared loans
             to read the value itself *)
          let p_v = value_strip_shared_loans p_v in
          (* Match *)
          match p_v.value with
          | VAdt adt -> (
              (* Evaluate the discriminant *)
              let dv = Option.get adt.variant_id in
              (* Find the branch, evaluate and continue *)
              match List.find_opt (fun (svl, _) -> List.mem dv svl) stgts with
              | None -> (
                  match otherwise with
                  | None -> raise (Failure "No otherwise branch")
                  | Some otherwise -> eval_statement config otherwise cf ctx)
              | Some (_, tgt) -> eval_statement config tgt cf ctx)
          | VSymbolic sv ->
              (* Expand the symbolic value - may lead to branching *)
              let cf_expand =
                expand_symbolic_adt config sv (Some (S.mk_mplace p ctx))
              in
              (* Re-evaluate the switch - the value is not symbolic anymore,
                 which means we will go to the other branch *)
              cf_expand (eval_switch config switch) cf ctx
          | _ -> raise (Failure "Inconsistent state")
        in
        (* Compose *)
        comp cf_read_p cf_match cf ctx
  in
  (* Compose the continuations *)
  cf_match cf ctx

(** Evaluate a function call (auxiliary helper for [eval_statement]) *)
and eval_function_call (config : config) (call : call) : st_cm_fun =
  (* There are several cases:
     - this is a local function, in which case we execute its body
     - this is an assumed function, in which case there is a special treatment
     - this is a trait method
  *)
  match config.mode with
  | ConcreteMode -> eval_function_call_concrete config call
  | SymbolicMode -> eval_function_call_symbolic config call

and eval_function_call_concrete (config : config) (call : call) : st_cm_fun =
 fun cf ctx ->
  match call.func with
  | FnOpMove _ -> raise (Failure "Closures are not supported yet")
  | FnOpRegular func -> (
      match func.func with
      | FunId (FRegular fid) ->
          eval_transparent_function_call_concrete config fid call cf ctx
      | FunId (FAssumed fid) ->
          (* Continue - note that we do as if the function call has been successful,
           * by giving {!Unit} to the continuation, because we place us in the case
           * where we haven't panicked. Of course, the translation needs to take the
           * panic case into account... *)
          eval_assumed_function_call_concrete config fid call (cf Unit) ctx
      | TraitMethod _ -> raise (Failure "Unimplemented"))

and eval_function_call_symbolic (config : config) (call : call) : st_cm_fun =
  match call.func with
  | FnOpMove _ -> raise (Failure "Closures are not supported yet")
  | FnOpRegular func -> (
      match func.func with
      | FunId (FRegular _) | TraitMethod _ ->
          eval_transparent_function_call_symbolic config call
      | FunId (FAssumed fid) ->
          eval_assumed_function_call_symbolic config fid call func)

(** Evaluate a local (i.e., non-assumed) function call in concrete mode *)
and eval_transparent_function_call_concrete (config : config)
    (fid : FunDeclId.id) (call : call) : st_cm_fun =
  let args = call.args in
  let dest = call.dest in
  match call.func with
  | FnOpMove _ -> raise (Failure "Closures are not supported yet")
  | FnOpRegular func ->
      let generics = func.generics in
      (* Sanity check: we don't fully handle the const generic vars environment
         in concrete mode yet *)
      assert (generics.const_generics = []);
      fun cf ctx ->
        (* Retrieve the (correctly instantiated) body *)
        let def = ctx_lookup_fun_decl ctx fid in
        (* We can evaluate the function call only if it is not opaque *)
        let body =
          match def.body with
          | None ->
              raise
                (Failure
                   ("Can't evaluate a call to an opaque function: "
                   ^ name_to_string ctx def.name))
          | Some body -> body
        in
        (* TODO: we need to normalize the types if we want to correctly support traits *)
        assert (generics.trait_refs = []);
        (* There shouldn't be any reference to Self *)
        let tr_self = UnknownTrait __FUNCTION__ in
        let subst =
          Subst.make_subst_from_generics def.signature.generics generics tr_self
        in
        let locals, body_st = Subst.fun_body_substitute_in_body subst body in

        (* Evaluate the input operands *)
        assert (List.length args = body.arg_count);
        let cc = eval_operands config args in

        (* Push a frame delimiter - we use {!comp_transmit} to transmit the result
         * of the operands evaluation from above to the functions afterwards, while
         * ignoring it in this function *)
        let cc = comp_transmit cc push_frame in

        (* Compute the initial values for the local variables *)
        (* 1. Push the return value *)
        let ret_var, locals =
          match locals with
          | ret_ty :: locals -> (ret_ty, locals)
          | _ -> raise (Failure "Unreachable")
        in
        let input_locals, locals =
          Collections.List.split_at locals body.arg_count
        in

        let cc =
          comp_transmit cc (push_var ret_var (mk_bottom ret_var.var_ty))
        in

        (* 2. Push the input values *)
        let cf_push_inputs cf args =
          let inputs = List.combine input_locals args in
          (* Note that this function checks that the variables and their values
           * have the same type (this is important) *)
          push_vars inputs cf
        in
        let cc = comp cc cf_push_inputs in

        (* 3. Push the remaining local variables (initialized as {!Bottom}) *)
        let cc = comp cc (push_uninitialized_vars locals) in

        (* Execute the function body *)
        let cc = comp cc (eval_function_body config body_st) in

        (* Pop the stack frame and move the return value to its destination *)
        let cf_finish cf res =
          match res with
          | Panic -> cf Panic
          | Return ->
              (* Pop the stack frame, retrieve the return value, move it to
               * its destination and continue *)
              pop_frame_assign config dest (cf Unit)
          | Break _ | Continue _ | Unit | LoopReturn _ | EndEnterLoop _
          | EndContinue _ ->
              raise (Failure "Unreachable")
        in
        let cc = comp cc cf_finish in

        (* Continue *)
        cc cf ctx

(** Evaluate a local (i.e., non-assumed) function call in symbolic mode *)
and eval_transparent_function_call_symbolic (config : config) (call : call) :
    st_cm_fun =
 fun cf ctx ->
  let func, generics, trait_method_generics, def, regions_hierarchy, inst_sg =
    eval_transparent_function_call_symbolic_inst call ctx
  in
  (* Sanity check *)
  assert (List.length call.args = List.length def.signature.inputs);
  (* Evaluate the function call *)
  eval_function_call_symbolic_from_inst_sig config func def.signature
    regions_hierarchy inst_sg generics trait_method_generics call.args call.dest
    cf ctx

(** Evaluate a function call in symbolic mode by using the function signature.

    This allows us to factorize the evaluation of local and non-local function
    calls in symbolic mode: only their signatures matter.

    The [self_trait_ref] trait ref refers to [Self]. We use it when calling
    a provided trait method, because those methods have a special treatment:
    we dot not group them with the required trait methods, and forbid (for now)
    overriding them. We treat them as regular method, which take an additional
    trait ref as input.
 *)
and eval_function_call_symbolic_from_inst_sig (config : config)
    (fid : fun_id_or_trait_method_ref) (sg : fun_sig)
    (regions_hierarchy : region_var_groups) (inst_sg : inst_fun_sig)
    (generics : generic_args)
    (trait_method_generics : (generic_args * trait_instance_id) option)
    (args : operand list) (dest : place) : st_cm_fun =
 fun cf ctx ->
  log#ldebug
    (lazy
      ("eval_function_call_symbolic_from_inst_sig:\n- fid: "
      ^ fun_id_or_trait_method_ref_to_string ctx fid
      ^ "\n- inst_sg:\n"
      ^ inst_fun_sig_to_string ctx inst_sg
      ^ "\n- call.generics:\n"
      ^ generic_args_to_string ctx generics
      ^ "\n- args:\n"
      ^ String.concat ", " (List.map (operand_to_string ctx) args)
      ^ "\n- dest:\n" ^ place_to_string ctx dest));

  (* Generate a fresh symbolic value for the return value *)
  let ret_sv_ty = inst_sg.output in
  let ret_spc = mk_fresh_symbolic_value ret_sv_ty in
  let ret_value = mk_typed_value_from_symbolic_value ret_spc in
  let ret_av regions =
    mk_aproj_loans_value_from_symbolic_value regions ret_spc
  in
  let args_places = List.map (fun p -> S.mk_opt_place_from_op p ctx) args in
  let dest_place = Some (S.mk_mplace dest ctx) in

  (* Evaluate the input operands *)
  let cc = eval_operands config args in

  (* Generate the abstractions and insert them in the context *)
  let abs_ids = List.map (fun rg -> rg.id) inst_sg.regions_hierarchy in
  let cf_call cf (args : typed_value list) : m_fun =
   fun ctx ->
    let args_with_rtypes = List.combine args inst_sg.inputs in

    (* Check the type of the input arguments *)
    assert (
      List.for_all
        (fun ((arg, rty) : typed_value * rty) ->
          arg.ty = Subst.erase_regions rty)
        args_with_rtypes);
    (* Check that the input arguments don't contain symbolic values that can't 
     * be fed to functions (i.e., symbolic values output from function return
     * values and which contain borrows of borrows can't be used as function
     * inputs *)
    assert (
      List.for_all
        (fun arg ->
          not (value_has_ret_symbolic_value_with_borrow_under_mut ctx arg))
        args);

    (* Initialize the abstractions and push them in the context.
     * First, we define the function which, given an initialized, empty
     * abstraction, computes the avalues which should be inserted inside.
     *)
    let compute_abs_avalues (abs : abs) (ctx : eval_ctx) :
        eval_ctx * typed_avalue list =
      (* Project over the input values *)
      let ctx, args_projs =
        List.fold_left_map
          (fun ctx (arg, arg_rty) ->
            apply_proj_borrows_on_input_value config ctx abs.regions
              abs.ancestors_regions arg arg_rty)
          ctx args_with_rtypes
      in
      (* Group the input and output values *)
      (ctx, List.append args_projs [ ret_av abs.regions ])
    in
    (* Actually initialize and insert the abstractions *)
    let call_id = fresh_fun_call_id () in
    let region_can_end _ = true in
    let ctx =
      create_push_abstractions_from_abs_region_groups
        (fun rg_id -> FunCall (call_id, rg_id))
        inst_sg.regions_hierarchy region_can_end compute_abs_avalues ctx
    in

    (* Apply the continuation *)
    let expr = cf ctx in

    (* Synthesize the symbolic AST *)
    S.synthesize_regular_function_call fid call_id ctx sg regions_hierarchy
      abs_ids generics trait_method_generics args args_places ret_spc dest_place
      expr
  in
  let cc = comp cc cf_call in

  (* Move the return value to its destination *)
  let cc = comp cc (assign_to_place config ret_value dest) in

  (* End the abstractions which don't contain loans and don't have parent
   * abstractions.
   * We do the general, nested borrows case here: we end abstractions, then
   * retry (because then we might end their children abstractions)
   *)
  let abs_ids = ref abs_ids in
  let rec end_abs_with_no_loans cf : m_fun =
   fun ctx ->
    (* Find the abstractions which don't contain loans *)
    let no_loans_abs, with_loans_abs =
      List.partition
        (fun abs_id ->
          (* Lookup the abstraction *)
          let abs = ctx_lookup_abs ctx abs_id in
          (* Check if it has parents *)
          AbstractionId.Set.is_empty abs.parents
          (* Check if it contains non-ignored loans *)
          && Option.is_none
               (InterpreterBorrowsCore
                .get_first_non_ignored_aloan_in_abstraction abs))
        !abs_ids
    in
    (* Check if there are abstractions to end *)
    if no_loans_abs <> [] then (
      (* Update the reference to the list of asbtraction ids, for the recursive calls *)
      abs_ids := with_loans_abs;
      (* End the abstractions which can be ended *)
      let no_loans_abs = AbstractionId.Set.of_list no_loans_abs in
      let cc = InterpreterBorrows.end_abstractions config no_loans_abs in
      (* Recursive call *)
      let cc = comp cc end_abs_with_no_loans in
      (* Continue *)
      cc cf ctx)
    else (* No abstractions to end: continue *)
      cf ctx
  in
  (* Try to end the abstractions with no loans if:
   * - the option is enabled
   * - the function returns unit
   * (see the documentation of {!config} for more information)
   *)
  let cc =
    if Config.return_unit_end_abs_with_no_loans && ty_is_unit inst_sg.output
    then comp cc end_abs_with_no_loans
    else cc
  in

  (* Continue - note that we do as if the function call has been successful,
   * by giving {!Unit} to the continuation, because we place us in the case
   * where we haven't panicked. Of course, the translation needs to take the
   * panic case into account... *)
  cc (cf Unit) ctx

(** Evaluate a non-local function call in symbolic mode *)
and eval_assumed_function_call_symbolic (config : config) (fid : assumed_fun_id)
    (call : call) (func : fn_ptr) : st_cm_fun =
 fun cf ctx ->
  let generics = func.generics in
  let args = call.args in
  let dest = call.dest in
  (* Sanity check: make sure the type parameters don't contain regions -
   * this is a current limitation of our synthesis *)
  assert (
    List.for_all
      (fun ty -> not (ty_has_borrows ctx.type_ctx.type_infos ty))
      generics.types);

  (* There are two cases (and this is extremely annoying):
     - the function is not box_free
     - the function is box_free
       See {!eval_box_free}
  *)
  match fid with
  | BoxFree ->
      (* Degenerate case: box_free - note that this is not really a function
       * call: no need to call a "synthesize_..." function *)
      eval_box_free config generics args dest (cf Unit) ctx
  | _ ->
      (* "Normal" case: not box_free *)
      (* In symbolic mode, the behaviour of a function call is completely defined
       * by the signature of the function: we thus simply generate correctly
       * instantiated signatures, and delegate the work to an auxiliary function *)
      let sg, regions_hierarchy, inst_sig =
        match fid with
        | BoxFree ->
            (* Should have been treated above *)
            raise (Failure "Unreachable")
        | _ ->
            let regions_hierarchy =
              LlbcAstUtils.FunIdMap.find (FAssumed fid)
                ctx.fun_ctx.regions_hierarchies
            in
            (* There shouldn't be any reference to Self *)
            let tr_self = UnknownTrait __FUNCTION__ in
            let sg = Assumed.get_assumed_fun_sig fid in
            let inst_sg =
              instantiate_fun_sig ctx generics tr_self sg regions_hierarchy
            in
            (sg, regions_hierarchy, inst_sg)
      in

      (* Evaluate the function call *)
      eval_function_call_symbolic_from_inst_sig config (FunId (FAssumed fid)) sg
        regions_hierarchy inst_sig generics None args dest cf ctx

(** Evaluate a statement seen as a function body *)
and eval_function_body (config : config) (body : statement) : st_cm_fun =
 fun cf ctx ->
  let cc = eval_statement config body in
  let cf_finish cf res =
    (* Note that we *don't* check the result ({!Panic}, {!Return}, etc.): we
     * delegate the check to the caller. *)
    (* Expand the symbolic values if necessary - we need to do that before
     * checking the invariants *)
    let cc = greedy_expand_symbolic_values config in
    (* Sanity check *)
    let cc = comp_check_ctx cc Invariants.check_invariants in
    (* Continue *)
    cc (cf res)
  in
  (* Compose and continue *)
  comp cc cf_finish cf ctx
