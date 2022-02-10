(** Properties about the hashmap *)
module Hashmap.Properties
open Primitives
open FStar.List.Tot
open FStar.Mul
open Hashmap.Types
open Hashmap.Clauses
open Hashmap.Funs

// To help with the proofs
module InteractiveHelpers = FStar.InteractiveHelpers

#set-options "--z3rlimit 50 --fuel 0 --ifuel 1"

(*** Lemmas about Primitives *)
/// TODO: move those lemmas

val list_update_index_dif_lem
  (#a : Type0) (ls : list a) (i : nat{i < length ls}) (x : a)
  (j : nat{j < length ls}) :
  Lemma (requires (j <> i))
  (ensures (index (list_update ls i x) j == index ls j))
  [SMTPat (index (list_update ls i x) j)]
#push-options "--fuel 1"
let rec list_update_index_dif_lem #a ls i x j =
  match ls with
  | x' :: ls ->
    if i = 0 then ()
    else if j = 0 then ()
    else
     list_update_index_dif_lem ls (i-1) x (j-1)
#pop-options


(*** Utilities *)

val pairwise_distinct : #a:eqtype -> ls:list a -> Tot bool
let rec pairwise_distinct (#a : eqtype) (ls : list a) : Tot bool =
  match ls with
  | [] -> true
  | x :: ls' -> List.Tot.for_all (fun y -> x <> y) ls' && pairwise_distinct ls'

val for_allP: #a:Type -> f:(a -> Tot Type0) -> list a -> Tot Type0
let rec for_allP (f : 'a -> Tot Type0) (l : list 'a) : Tot Type0 =
  match l with
  | [] -> True
  | hd::tl -> f hd /\ for_allP f tl

val pairwise_relP : #a:Type -> pred:(a -> a -> Tot Type0) -> ls:list a -> Tot Type0
let rec pairwise_relP #a pred ls =
  match ls with
  | [] -> True
  | x :: ls' ->
    for_allP (pred x) ls' /\ pairwise_relP pred ls'

val pairwise_rel : #a:Type -> pred:(a -> a -> Tot bool) -> ls:list a -> Tot bool
let rec pairwise_rel #a pred ls =
  match ls with
  | [] -> true
  | x :: ls' ->
    List.Tot.for_all (pred x) ls' && pairwise_rel pred ls' 

/// The lack of lemmas about list manipulation is really annoying...

#push-options "--fuel 1"
let rec flatten_append (#a : Type) (l1 l2: list (list a)) :
  Lemma (flatten (l1 @ l2) == flatten l1 @ flatten l2) =
  match l1 with
  | [] -> ()
  | x :: l1' ->
    flatten_append l1' l2;
    append_assoc x (flatten l1') (flatten l2)
#pop-options

/// We don't use anonymous functions as parameters to other functions, but rather
/// introduce auxiliary functions instead: otherwise we can't reason (because
/// F*'s encoding to the SMT is imprecise for functions)
let fst_is_disctinct (#a : eqtype) (#b : Type0) (p0 : a & b) (p1 : a & b) : Type0 =
  fst p0 <> fst p1

(*** Invariants, representants *)

/// "Natural" length function for [list_t]
let rec list_t_len (#t : Type0) (ls : list_t t) : nat =
  match ls with
  | ListNil -> 0
  | ListCons _ _ tl -> 1 + list_t_len tl

/// The "key" type
type key = usize

type binding (t : Type0) = key & t

type slots_t (t : Type0) = vec (list_t t)

/// We represent hash maps as associative lists
type assoc_list (t : Type0) = list (binding t)

/// Representation function for [list_t]
let rec list_t_v (#t : Type0) (ls : list_t t) : assoc_list t =
  match ls with
  | ListNil -> []
  | ListCons k v tl -> (k,v) :: list_t_v tl

/// Representation function for the slots.
/// Rk.: I hesitated to use [concatMap]
let slots_t_v (#t : Type0) (slots : slots_t t) : assoc_list t =
  flatten (map list_t_v slots)

/// Representation function for [hash_map_t]
let hash_map_t_v (#t : Type0) (hm : hash_map_t t) : assoc_list t =
  slots_t_v hm.hash_map_slots

let same_key (#t : Type0) (k : key) (b : binding t) : bool = fst b = k
let binding_neq (#t : Type0) (b0 b1 : binding t) : bool = fst b0 <> fst b1

let has_same_binding (#t : Type0) (al : assoc_list t) ((k,v) : binding t) : Type0 =
  match find (same_key k) al with
  | None -> False
  | Some (k',v') -> v' == v

/// Auxiliary function stating that two associative lists are "equivalent"
let assoc_list_equiv (#t : Type0) (al0 al1 : assoc_list t) : Type0 =
  // All the bindings in al0 can be found in al1
  for_allP (has_same_binding al1) al0 /\
  // And the reverse is true
  for_allP (has_same_binding al0) al1

/// Base invariant for the hashmap (might temporarily be broken at some point)
let hash_map_t_base_inv (#t : Type0) (hm : hash_map_t t) : Type0 =
  let al = hash_map_t_v hm in
  // [num_entries] correctly tracks the number of entries in the table
  hm.hash_map_num_entries = length al /\
  // All the keys are pairwise distinct
  pairwise_rel binding_neq al /\
  // The capacity must be > 0 (otherwise we can't resize, because we multiply
  // the capacity by two!)
  length hm.hash_map_slots > 0 /\
  // Load computation
  begin
  let capacity = length hm.hash_map_slots in
  let (dividend, divisor) = hm.hash_map_max_load_factor in
  0 < dividend /\ dividend < divisor /\
  hm.hash_map_max_load = (capacity * dividend) / divisor
  end

/// Invariant for the hashmap
let hash_map_t_inv (#t : Type0) (hm : hash_map_t t) : Type0 =
  // Base invariant
  hash_map_t_base_inv hm /\
  // The hash map is either: not overloaded, or we can't resize it
  (hm.hash_map_num_entries <= hm.hash_map_max_load
   || length hm.hash_map_slots * 2 > usize_max)

/// The following predicate links the hashmap to an associative list.
/// Note that it does not compute the representant: different (permuted)
/// lists can be used to represent the same hashmap!
let hash_map_t_is_al (#t : Type0) (hm : hash_map_t t) (al : assoc_list t) : Type0 =
  let hm_al = hash_map_t_v hm in
  assoc_list_equiv hm_al al

/// The invariant we reveal to the user
let hash_map_t_inv_repr (#t : Type0) (hm : hash_map_t t) (al : assoc_list t) : Type0 =
  // The hash map invariant is satisfied
  hash_map_t_inv hm /\
  // And it can be seen as the given associative list
  hash_map_t_is_al hm al

let hash_map_len (#t : Type0) (hm : hash_map_t t) : nat =
  hm.hash_map_num_entries

(*** Proofs *)
(**** allocate_slots *)
val hash_map_allocate_slots_fwd_lem
  (t : Type0) (slots : vec (list_t t)) (n : usize) :
  Lemma
  (requires (slots_t_v slots == [] /\ length slots + n <= usize_max))
  (ensures (
   match hash_map_allocate_slots_fwd t slots n with
   | Fail -> False
   | Return slots' ->
     slots_t_v slots' == [] /\
     length slots' = length slots + n))
  (decreases (hash_map_allocate_slots_decreases t slots n))

#push-options "--fuel 1"
let rec hash_map_allocate_slots_fwd_lem t slots n =
  if n = 0 then ()
  else
    begin match vec_push_back (list_t t) slots ListNil with
    | Fail -> assert(False)
    | Return v ->
      (* Prove that the new slots [v] represent an empty mapping *)
      assert(v == slots @ [ListNil]);
      map_append list_t_v slots [ListNil];
      assert(map list_t_v v == map list_t_v slots @ map list_t_v [ListNil]);
      assert_norm(map (list_t_v #t) [ListNil] == [[]]);
      flatten_append (map list_t_v slots) [[]];
      assert(slots_t_v v == slots_t_v slots @ slots_t_v [ListNil]);
      assert_norm(slots_t_v #t [ListNil] == []);
      assert(slots_t_v v == slots_t_v slots @ []);
      assert(slots_t_v v == slots_t_v slots);
      assert(slots_t_v v == []);
      begin match usize_sub n 1 with
      | Fail -> assert(False)
      | Return i ->
        hash_map_allocate_slots_fwd_lem t v i;
        begin match hash_map_allocate_slots_fwd t v i with
        | Fail -> assert(False)
        | Return v0 -> ()
        end
      end
    end
#pop-options

(**** new_with_capacity *)
/// Under proper conditions, [new_with_capacity] doesn't fail and returns an empty hash map.
val hash_map_new_with_capacity_fwd_lem
  (t : Type0) (capacity : usize)
  (max_load_dividend : usize) (max_load_divisor : usize) :
  Lemma
  (requires (
    0 < max_load_dividend /\
    max_load_dividend < max_load_divisor /\
    0 < capacity /\
    capacity * max_load_dividend < usize_max))
  (ensures (
    match hash_map_new_with_capacity_fwd t capacity max_load_dividend max_load_divisor with
    | Fail -> False
    | Return hm -> hash_map_t_inv_repr hm []))

#push-options "--fuel 1"
let hash_map_new_with_capacity_fwd_lem (t : Type0) (capacity : usize)
  (max_load_dividend : usize) (max_load_divisor : usize) =
  let v = vec_new (list_t t) in
  assert(length v = 0);
  hash_map_allocate_slots_fwd_lem t v capacity;
  begin match hash_map_allocate_slots_fwd t v capacity with
  | Fail -> assert(False)
  | Return v0 ->
    begin match usize_mul capacity max_load_dividend with
    | Fail -> assert(False)
    | Return i ->
      begin match usize_div i max_load_divisor with
      | Fail -> assert(False)
      | Return i0 ->
          let hm = Mkhash_map_t 0 (max_load_dividend, max_load_divisor) i0 v0 in
          // The base invariant
          let al = hash_map_t_v hm in
          assert(hash_map_t_base_inv hm);
          assert(hash_map_t_inv hm);
          assert(hash_map_t_is_al hm [])
      end
    end
  end
#pop-options

(**** new *)
/// [new] doesn't fail and returns an empty hash map.
val hash_map_new_fwd_lem (t : Type0) :
  Lemma
  (ensures (
    match hash_map_new_fwd t with
    | Fail -> False
    | Return hm -> hash_map_t_inv_repr hm []))

let hash_map_new_fwd_lem t = hash_map_new_with_capacity_fwd_lem t 32 4 5

(**** clear_slots *)
/// [clear_slots] doesn't fail and simply clears the slots starting at index i
#push-options "--fuel 1"
let rec hash_map_clear_slots_fwd_back_lem
  (t : Type0) (slots : vec (list_t t)) (i : usize) :
  Lemma
  (ensures (
    match hash_map_clear_slots_fwd_back t slots i with
    | Fail -> False
    | Return slots' ->
      // The length is preserved
      length slots' == length slots /\
      // The slots before i are left unchanged
      (forall (j:nat{j < i /\ j < length slots}). index slots' j == index slots j) /\
      // The slots after i are set to ListNil
      (forall (j:nat{i <= j /\ j < length slots}). index slots' j == ListNil)))
  (decreases (hash_map_clear_slots_decreases t slots i))
  =
  let i0 = vec_len (list_t t) slots in
  let b = i < i0 in
  if b
  then
    begin match vec_index_mut_back (list_t t) slots i ListNil with
    | Fail -> ()
    | Return v ->
      begin match usize_add i 1 with
      | Fail -> ()
      | Return i1 ->
        hash_map_clear_slots_fwd_back_lem t v i1;
        begin match hash_map_clear_slots_fwd_back t v i1 with
        | Fail -> ()
        | Return slots1 ->
          assert(length slots1 == length slots);
          assert(forall (j:nat{i+1 <= j /\ j < length slots}). index slots1 j == ListNil);
          assert(index slots1 i == ListNil)
        end
      end
    end
  else ()
#pop-options

/// Auxiliary lemma:
/// if all the slots in a vector are [ListNil], then this vector viewed as a list
/// is empty.
#push-options "--fuel 1"
let rec slots_t_v_all_nil_is_empty_lem (#t : Type0) (slots : slots_t t) :
  Lemma (requires (forall (i:nat{i < length slots}). index slots i == ListNil))
  (ensures (slots_t_v slots == []))
  =
  match slots with
  | [] -> ()
  | s :: slots' ->
    (* The following assert helps the instantiation of quantifiers... *)
    assert(forall (i:nat{i < length slots'}). index slots' i == index slots (i+1));
    slots_t_v_all_nil_is_empty_lem slots';
    assert(slots_t_v slots == flatten (map list_t_v (s :: slots')));
    assert(slots_t_v slots == flatten (list_t_v s :: map list_t_v slots'));
    assert(slots_t_v slots == append (list_t_v s) (flatten (map list_t_v slots')));
    assert(slots_t_v slots == append (list_t_v s) (flatten (map list_t_v slots')));
    assert(slots_t_v slots == append (list_t_v s) []);
    assert(slots_t_v slots == (list_t_v s) @ []); // Triggers an SMT pat
    assert(slots_t_v slots == list_t_v s);
    assert(index slots 0 == s);
    assert(slots_t_v slots == [])
#pop-options

(**** clear *)
/// [clear] doesn't fail and turns the hash map into an empty map
val hash_map_clear_fwd_back_lem
  (t : Type0) (self : hash_map_t t) :
  Lemma
  (requires (hash_map_t_inv self))
  (ensures (
    match hash_map_clear_fwd_back t self with
    | Fail -> False
    | Return hm ->
      hash_map_t_inv_repr hm []))

// Being lazy: fuel 1 helps a lot...
#push-options "--fuel 1"
let hash_map_clear_fwd_back_lem t self =
  let p = self.hash_map_max_load_factor in
  let i = self.hash_map_max_load in
  let v = self.hash_map_slots in
  hash_map_clear_slots_fwd_back_lem t v 0;
  begin match hash_map_clear_slots_fwd_back t v 0 with
  | Fail -> ()
  | Return slots1 ->
    slots_t_v_all_nil_is_empty_lem slots1;
    let hm1 = Mkhash_map_t 0 p i slots1 in
    assert(hash_map_t_base_inv hm1);
    assert(hash_map_t_inv hm1);
    assert(hash_map_t_is_al hm1 []);
    assert(hash_map_t_inv_repr hm1 [])
  end
#pop-options

(**** len *)

/// [len]: we link it to a non-failing function.
/// Rk.: we might want to make an analysis to not use an error monad to translate
/// functions which statically can't fail.
val hash_map_len_fwd_lem (t : Type0) (self : hash_map_t t) :
  Lemma (
    match hash_map_len_fwd t self with
    | Fail -> False
    | Return l -> l = hash_map_len self)

let hash_map_len_fwd_lem t self = ()


(**** insert_in_list *)
