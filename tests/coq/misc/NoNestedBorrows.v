(** THIS FILE WAS AUTOMATICALLY GENERATED BY AENEAS *)
(** [no_nested_borrows] *)
Require Import Primitives.
Import Primitives.
Require Import Coq.ZArith.ZArith.
Require Import List.
Import ListNotations.
Local Open Scope Primitives_scope.
Module NoNestedBorrows.

(** [no_nested_borrows::Pair]
    Source: 'src/no_nested_borrows.rs', lines 4:0-4:23 *)
Record Pair_t (T1 T2 : Type) := mkPair_t { pair_x : T1; pair_y : T2; }.

Arguments mkPair_t { _ _ }.
Arguments pair_x { _ _ }.
Arguments pair_y { _ _ }.

(** [no_nested_borrows::List]
    Source: 'src/no_nested_borrows.rs', lines 9:0-9:16 *)
Inductive List_t (T : Type) :=
| List_Cons : T -> List_t T -> List_t T
| List_Nil : List_t T
.

Arguments List_Cons { _ }.
Arguments List_Nil { _ }.

(** [no_nested_borrows::One]
    Source: 'src/no_nested_borrows.rs', lines 20:0-20:16 *)
Inductive One_t (T1 : Type) := | One_One : T1 -> One_t T1.

Arguments One_One { _ }.

(** [no_nested_borrows::EmptyEnum]
    Source: 'src/no_nested_borrows.rs', lines 26:0-26:18 *)
Inductive EmptyEnum_t := | EmptyEnum_Empty : EmptyEnum_t.

(** [no_nested_borrows::Enum]
    Source: 'src/no_nested_borrows.rs', lines 32:0-32:13 *)
Inductive Enum_t := | Enum_Variant1 : Enum_t | Enum_Variant2 : Enum_t.

(** [no_nested_borrows::EmptyStruct]
    Source: 'src/no_nested_borrows.rs', lines 39:0-39:22 *)
Definition EmptyStruct_t : Type := unit.

(** [no_nested_borrows::Sum]
    Source: 'src/no_nested_borrows.rs', lines 41:0-41:20 *)
Inductive Sum_t (T1 T2 : Type) :=
| Sum_Left : T1 -> Sum_t T1 T2
| Sum_Right : T2 -> Sum_t T1 T2
.

Arguments Sum_Left { _ _ }.
Arguments Sum_Right { _ _ }.

(** [no_nested_borrows::neg_test]:
    Source: 'src/no_nested_borrows.rs', lines 48:0-48:30 *)
Definition neg_test (x : i32) : result i32 :=
  i32_neg x.

(** [no_nested_borrows::add_u32]:
    Source: 'src/no_nested_borrows.rs', lines 54:0-54:37 *)
Definition add_u32 (x : u32) (y : u32) : result u32 :=
  u32_add x y.

(** [no_nested_borrows::subs_u32]:
    Source: 'src/no_nested_borrows.rs', lines 60:0-60:38 *)
Definition subs_u32 (x : u32) (y : u32) : result u32 :=
  u32_sub x y.

(** [no_nested_borrows::div_u32]:
    Source: 'src/no_nested_borrows.rs', lines 66:0-66:37 *)
Definition div_u32 (x : u32) (y : u32) : result u32 :=
  u32_div x y.

(** [no_nested_borrows::div_u32_const]:
    Source: 'src/no_nested_borrows.rs', lines 73:0-73:35 *)
Definition div_u32_const (x : u32) : result u32 :=
  u32_div x 2%u32.

(** [no_nested_borrows::rem_u32]:
    Source: 'src/no_nested_borrows.rs', lines 78:0-78:37 *)
Definition rem_u32 (x : u32) (y : u32) : result u32 :=
  u32_rem x y.

(** [no_nested_borrows::mul_u32]:
    Source: 'src/no_nested_borrows.rs', lines 82:0-82:37 *)
Definition mul_u32 (x : u32) (y : u32) : result u32 :=
  u32_mul x y.

(** [no_nested_borrows::add_i32]:
    Source: 'src/no_nested_borrows.rs', lines 88:0-88:37 *)
Definition add_i32 (x : i32) (y : i32) : result i32 :=
  i32_add x y.

(** [no_nested_borrows::subs_i32]:
    Source: 'src/no_nested_borrows.rs', lines 92:0-92:38 *)
Definition subs_i32 (x : i32) (y : i32) : result i32 :=
  i32_sub x y.

(** [no_nested_borrows::div_i32]:
    Source: 'src/no_nested_borrows.rs', lines 96:0-96:37 *)
Definition div_i32 (x : i32) (y : i32) : result i32 :=
  i32_div x y.

(** [no_nested_borrows::div_i32_const]:
    Source: 'src/no_nested_borrows.rs', lines 100:0-100:35 *)
Definition div_i32_const (x : i32) : result i32 :=
  i32_div x 2%i32.

(** [no_nested_borrows::rem_i32]:
    Source: 'src/no_nested_borrows.rs', lines 104:0-104:37 *)
Definition rem_i32 (x : i32) (y : i32) : result i32 :=
  i32_rem x y.

(** [no_nested_borrows::mul_i32]:
    Source: 'src/no_nested_borrows.rs', lines 108:0-108:37 *)
Definition mul_i32 (x : i32) (y : i32) : result i32 :=
  i32_mul x y.

(** [no_nested_borrows::mix_arith_u32]:
    Source: 'src/no_nested_borrows.rs', lines 112:0-112:51 *)
Definition mix_arith_u32 (x : u32) (y : u32) (z : u32) : result u32 :=
  i <- u32_add x y;
  i1 <- u32_div x y;
  i2 <- u32_mul i i1;
  i3 <- u32_rem z y;
  i4 <- u32_sub x i3;
  i5 <- u32_add i2 i4;
  i6 <- u32_add x y;
  i7 <- u32_add i6 z;
  u32_rem i5 i7
.

(** [no_nested_borrows::mix_arith_i32]:
    Source: 'src/no_nested_borrows.rs', lines 116:0-116:51 *)
Definition mix_arith_i32 (x : i32) (y : i32) (z : i32) : result i32 :=
  i <- i32_add x y;
  i1 <- i32_div x y;
  i2 <- i32_mul i i1;
  i3 <- i32_rem z y;
  i4 <- i32_sub x i3;
  i5 <- i32_add i2 i4;
  i6 <- i32_add x y;
  i7 <- i32_add i6 z;
  i32_rem i5 i7
.

(** [no_nested_borrows::CONST0]
    Source: 'src/no_nested_borrows.rs', lines 125:0-125:23 *)
Definition const0_body : result usize := usize_add 1%usize 1%usize.
Definition const0_c : usize := const0_body%global.

(** [no_nested_borrows::CONST1]
    Source: 'src/no_nested_borrows.rs', lines 126:0-126:23 *)
Definition const1_body : result usize := usize_mul 2%usize 2%usize.
Definition const1_c : usize := const1_body%global.

(** [no_nested_borrows::cast_u32_to_i32]:
    Source: 'src/no_nested_borrows.rs', lines 128:0-128:37 *)
Definition cast_u32_to_i32 (x : u32) : result i32 :=
  scalar_cast U32 I32 x.

(** [no_nested_borrows::cast_bool_to_i32]:
    Source: 'src/no_nested_borrows.rs', lines 132:0-132:39 *)
Definition cast_bool_to_i32 (x : bool) : result i32 :=
  scalar_cast_bool I32 x.

(** [no_nested_borrows::cast_bool_to_bool]:
    Source: 'src/no_nested_borrows.rs', lines 137:0-137:41 *)
Definition cast_bool_to_bool (x : bool) : result bool :=
  Return x.

(** [no_nested_borrows::test2]:
    Source: 'src/no_nested_borrows.rs', lines 142:0-142:14 *)
Definition test2 : result unit :=
  _ <- u32_add 23%u32 44%u32; Return tt.

(** Unit test for [no_nested_borrows::test2] *)
Check (test2 )%return.

(** [no_nested_borrows::get_max]:
    Source: 'src/no_nested_borrows.rs', lines 154:0-154:37 *)
Definition get_max (x : u32) (y : u32) : result u32 :=
  if x s>= y then Return x else Return y
.

(** [no_nested_borrows::test3]:
    Source: 'src/no_nested_borrows.rs', lines 162:0-162:14 *)
Definition test3 : result unit :=
  x <- get_max 4%u32 3%u32;
  y <- get_max 10%u32 11%u32;
  z <- u32_add x y;
  if negb (z s= 15%u32) then Fail_ Failure else Return tt
.

(** Unit test for [no_nested_borrows::test3] *)
Check (test3 )%return.

(** [no_nested_borrows::test_neg1]:
    Source: 'src/no_nested_borrows.rs', lines 169:0-169:18 *)
Definition test_neg1 : result unit :=
  y <- i32_neg 3%i32; if negb (y s= (-3)%i32) then Fail_ Failure else Return tt
.

(** Unit test for [no_nested_borrows::test_neg1] *)
Check (test_neg1 )%return.

(** [no_nested_borrows::refs_test1]:
    Source: 'src/no_nested_borrows.rs', lines 176:0-176:19 *)
Definition refs_test1 : result unit :=
  if negb (1%i32 s= 1%i32) then Fail_ Failure else Return tt
.

(** Unit test for [no_nested_borrows::refs_test1] *)
Check (refs_test1 )%return.

(** [no_nested_borrows::refs_test2]:
    Source: 'src/no_nested_borrows.rs', lines 187:0-187:19 *)
Definition refs_test2 : result unit :=
  if negb (2%i32 s= 2%i32)
  then Fail_ Failure
  else
    if negb (0%i32 s= 0%i32)
    then Fail_ Failure
    else
      if negb (2%i32 s= 2%i32)
      then Fail_ Failure
      else if negb (2%i32 s= 2%i32) then Fail_ Failure else Return tt
.

(** Unit test for [no_nested_borrows::refs_test2] *)
Check (refs_test2 )%return.

(** [no_nested_borrows::test_list1]:
    Source: 'src/no_nested_borrows.rs', lines 203:0-203:19 *)
Definition test_list1 : result unit :=
  Return tt.

(** Unit test for [no_nested_borrows::test_list1] *)
Check (test_list1 )%return.

(** [no_nested_borrows::test_box1]:
    Source: 'src/no_nested_borrows.rs', lines 208:0-208:18 *)
Definition test_box1 : result unit :=
  p <- alloc_boxed_Box_deref_mut i32 0%i32;
  let (_, deref_mut_back) := p in
  b <- deref_mut_back 1%i32;
  x <- alloc_boxed_Box_deref i32 b;
  if negb (x s= 1%i32) then Fail_ Failure else Return tt
.

(** Unit test for [no_nested_borrows::test_box1] *)
Check (test_box1 )%return.

(** [no_nested_borrows::copy_int]:
    Source: 'src/no_nested_borrows.rs', lines 218:0-218:30 *)
Definition copy_int (x : i32) : result i32 :=
  Return x.

(** [no_nested_borrows::test_unreachable]:
    Source: 'src/no_nested_borrows.rs', lines 224:0-224:32 *)
Definition test_unreachable (b : bool) : result unit :=
  if b then Fail_ Failure else Return tt
.

(** [no_nested_borrows::test_panic]:
    Source: 'src/no_nested_borrows.rs', lines 232:0-232:26 *)
Definition test_panic (b : bool) : result unit :=
  if b then Fail_ Failure else Return tt
.

(** [no_nested_borrows::test_copy_int]:
    Source: 'src/no_nested_borrows.rs', lines 239:0-239:22 *)
Definition test_copy_int : result unit :=
  y <- copy_int 0%i32; if negb (0%i32 s= y) then Fail_ Failure else Return tt
.

(** Unit test for [no_nested_borrows::test_copy_int] *)
Check (test_copy_int )%return.

(** [no_nested_borrows::is_cons]:
    Source: 'src/no_nested_borrows.rs', lines 246:0-246:38 *)
Definition is_cons (T : Type) (l : List_t T) : result bool :=
  match l with | List_Cons _ _ => Return true | List_Nil => Return false end
.

(** [no_nested_borrows::test_is_cons]:
    Source: 'src/no_nested_borrows.rs', lines 253:0-253:21 *)
Definition test_is_cons : result unit :=
  b <- is_cons i32 (List_Cons 0%i32 List_Nil);
  if negb b then Fail_ Failure else Return tt
.

(** Unit test for [no_nested_borrows::test_is_cons] *)
Check (test_is_cons )%return.

(** [no_nested_borrows::split_list]:
    Source: 'src/no_nested_borrows.rs', lines 259:0-259:48 *)
Definition split_list (T : Type) (l : List_t T) : result (T * (List_t T)) :=
  match l with
  | List_Cons hd tl => Return (hd, tl)
  | List_Nil => Fail_ Failure
  end
.

(** [no_nested_borrows::test_split_list]:
    Source: 'src/no_nested_borrows.rs', lines 267:0-267:24 *)
Definition test_split_list : result unit :=
  p <- split_list i32 (List_Cons 0%i32 List_Nil);
  let (hd, _) := p in
  if negb (hd s= 0%i32) then Fail_ Failure else Return tt
.

(** Unit test for [no_nested_borrows::test_split_list] *)
Check (test_split_list )%return.

(** [no_nested_borrows::choose]:
    Source: 'src/no_nested_borrows.rs', lines 274:0-274:70 *)
Definition choose
  (T : Type) (b : bool) (x : T) (y : T) : result (T * (T -> result (T * T))) :=
  if b
  then let back_'a := fun (ret : T) => Return (ret, y) in Return (x, back_'a)
  else let back_'a := fun (ret : T) => Return (x, ret) in Return (y, back_'a)
.

(** [no_nested_borrows::choose_test]:
    Source: 'src/no_nested_borrows.rs', lines 282:0-282:20 *)
Definition choose_test : result unit :=
  p <- choose i32 true 0%i32 0%i32;
  let (z, choose_back) := p in
  z1 <- i32_add z 1%i32;
  if negb (z1 s= 1%i32)
  then Fail_ Failure
  else (
    p1 <- choose_back z1;
    let (x, y) := p1 in
    if negb (x s= 1%i32)
    then Fail_ Failure
    else if negb (y s= 0%i32) then Fail_ Failure else Return tt)
.

(** Unit test for [no_nested_borrows::choose_test] *)
Check (choose_test )%return.

(** [no_nested_borrows::test_char]:
    Source: 'src/no_nested_borrows.rs', lines 294:0-294:26 *)
Definition test_char : result char :=
  Return (char_of_byte Coq.Init.Byte.x61).

(** [no_nested_borrows::Tree]
    Source: 'src/no_nested_borrows.rs', lines 299:0-299:16 *)
Inductive Tree_t (T : Type) :=
| Tree_Leaf : T -> Tree_t T
| Tree_Node : T -> NodeElem_t T -> Tree_t T -> Tree_t T

(** [no_nested_borrows::NodeElem]
    Source: 'src/no_nested_borrows.rs', lines 304:0-304:20 *)
with NodeElem_t (T : Type) :=
| NodeElem_Cons : Tree_t T -> NodeElem_t T -> NodeElem_t T
| NodeElem_Nil : NodeElem_t T
.

Arguments Tree_Leaf { _ }.
Arguments Tree_Node { _ }.

Arguments NodeElem_Cons { _ }.
Arguments NodeElem_Nil { _ }.

(** [no_nested_borrows::list_length]:
    Source: 'src/no_nested_borrows.rs', lines 339:0-339:48 *)
Fixpoint list_length (T : Type) (l : List_t T) : result u32 :=
  match l with
  | List_Cons _ l1 => i <- list_length T l1; u32_add 1%u32 i
  | List_Nil => Return 0%u32
  end
.

(** [no_nested_borrows::list_nth_shared]:
    Source: 'src/no_nested_borrows.rs', lines 347:0-347:62 *)
Fixpoint list_nth_shared (T : Type) (l : List_t T) (i : u32) : result T :=
  match l with
  | List_Cons x tl =>
    if i s= 0%u32
    then Return x
    else (i1 <- u32_sub i 1%u32; list_nth_shared T tl i1)
  | List_Nil => Fail_ Failure
  end
.

(** [no_nested_borrows::list_nth_mut]:
    Source: 'src/no_nested_borrows.rs', lines 363:0-363:67 *)
Fixpoint list_nth_mut
  (T : Type) (l : List_t T) (i : u32) :
  result (T * (T -> result (List_t T)))
  :=
  match l with
  | List_Cons x tl =>
    if i s= 0%u32
    then
      let back_'a := fun (ret : T) => Return (List_Cons ret tl) in
      Return (x, back_'a)
    else (
      i1 <- u32_sub i 1%u32;
      p <- list_nth_mut T tl i1;
      let (t, list_nth_mut_back) := p in
      let back_'a :=
        fun (ret : T) => tl1 <- list_nth_mut_back ret; Return (List_Cons x tl1)
        in
      Return (t, back_'a))
  | List_Nil => Fail_ Failure
  end
.

(** [no_nested_borrows::list_rev_aux]:
    Source: 'src/no_nested_borrows.rs', lines 379:0-379:63 *)
Fixpoint list_rev_aux
  (T : Type) (li : List_t T) (lo : List_t T) : result (List_t T) :=
  match li with
  | List_Cons hd tl => list_rev_aux T tl (List_Cons hd lo)
  | List_Nil => Return lo
  end
.

(** [no_nested_borrows::list_rev]:
    Source: 'src/no_nested_borrows.rs', lines 393:0-393:42 *)
Definition list_rev (T : Type) (l : List_t T) : result (List_t T) :=
  let (li, _) := core_mem_replace (List_t T) l List_Nil in
  list_rev_aux T li List_Nil
.

(** [no_nested_borrows::test_list_functions]:
    Source: 'src/no_nested_borrows.rs', lines 398:0-398:28 *)
Definition test_list_functions : result unit :=
  let l := List_Cons 2%i32 List_Nil in
  let l1 := List_Cons 1%i32 l in
  i <- list_length i32 (List_Cons 0%i32 l1);
  if negb (i s= 3%u32)
  then Fail_ Failure
  else (
    i1 <- list_nth_shared i32 (List_Cons 0%i32 l1) 0%u32;
    if negb (i1 s= 0%i32)
    then Fail_ Failure
    else (
      i2 <- list_nth_shared i32 (List_Cons 0%i32 l1) 1%u32;
      if negb (i2 s= 1%i32)
      then Fail_ Failure
      else (
        i3 <- list_nth_shared i32 (List_Cons 0%i32 l1) 2%u32;
        if negb (i3 s= 2%i32)
        then Fail_ Failure
        else (
          p <- list_nth_mut i32 (List_Cons 0%i32 l1) 1%u32;
          let (_, list_nth_mut_back) := p in
          ls <- list_nth_mut_back 3%i32;
          i4 <- list_nth_shared i32 ls 0%u32;
          if negb (i4 s= 0%i32)
          then Fail_ Failure
          else (
            i5 <- list_nth_shared i32 ls 1%u32;
            if negb (i5 s= 3%i32)
            then Fail_ Failure
            else (
              i6 <- list_nth_shared i32 ls 2%u32;
              if negb (i6 s= 2%i32) then Fail_ Failure else Return tt))))))
.

(** Unit test for [no_nested_borrows::test_list_functions] *)
Check (test_list_functions )%return.

(** [no_nested_borrows::id_mut_pair1]:
    Source: 'src/no_nested_borrows.rs', lines 414:0-414:89 *)
Definition id_mut_pair1
  (T1 T2 : Type) (x : T1) (y : T2) :
  result ((T1 * T2) * ((T1 * T2) -> result (T1 * T2)))
  :=
  let back_'a := fun (ret : (T1 * T2)) => let (t, t1) := ret in Return (t, t1)
    in
  Return ((x, y), back_'a)
.

(** [no_nested_borrows::id_mut_pair2]:
    Source: 'src/no_nested_borrows.rs', lines 418:0-418:88 *)
Definition id_mut_pair2
  (T1 T2 : Type) (p : (T1 * T2)) :
  result ((T1 * T2) * ((T1 * T2) -> result (T1 * T2)))
  :=
  let (t, t1) := p in
  let back_'a :=
    fun (ret : (T1 * T2)) => let (t2, t3) := ret in Return (t2, t3) in
  Return ((t, t1), back_'a)
.

(** [no_nested_borrows::id_mut_pair3]:
    Source: 'src/no_nested_borrows.rs', lines 422:0-422:93 *)
Definition id_mut_pair3
  (T1 T2 : Type) (x : T1) (y : T2) :
  result ((T1 * T2) * (T1 -> result T1) * (T2 -> result T2))
  :=
  Return ((x, y), Return, Return)
.

(** [no_nested_borrows::id_mut_pair4]:
    Source: 'src/no_nested_borrows.rs', lines 426:0-426:92 *)
Definition id_mut_pair4
  (T1 T2 : Type) (p : (T1 * T2)) :
  result ((T1 * T2) * (T1 -> result T1) * (T2 -> result T2))
  :=
  let (t, t1) := p in Return ((t, t1), Return, Return)
.

(** [no_nested_borrows::StructWithTuple]
    Source: 'src/no_nested_borrows.rs', lines 433:0-433:34 *)
Record StructWithTuple_t (T1 T2 : Type) :=
mkStructWithTuple_t {
  structWithTuple_p : (T1 * T2);
}
.

Arguments mkStructWithTuple_t { _ _ }.
Arguments structWithTuple_p { _ _ }.

(** [no_nested_borrows::new_tuple1]:
    Source: 'src/no_nested_borrows.rs', lines 437:0-437:48 *)
Definition new_tuple1 : result (StructWithTuple_t u32 u32) :=
  Return {| structWithTuple_p := (1%u32, 2%u32) |}
.

(** [no_nested_borrows::new_tuple2]:
    Source: 'src/no_nested_borrows.rs', lines 441:0-441:48 *)
Definition new_tuple2 : result (StructWithTuple_t i16 i16) :=
  Return {| structWithTuple_p := (1%i16, 2%i16) |}
.

(** [no_nested_borrows::new_tuple3]:
    Source: 'src/no_nested_borrows.rs', lines 445:0-445:48 *)
Definition new_tuple3 : result (StructWithTuple_t u64 i64) :=
  Return {| structWithTuple_p := (1%u64, 2%i64) |}
.

(** [no_nested_borrows::StructWithPair]
    Source: 'src/no_nested_borrows.rs', lines 450:0-450:33 *)
Record StructWithPair_t (T1 T2 : Type) :=
mkStructWithPair_t {
  structWithPair_p : Pair_t T1 T2;
}
.

Arguments mkStructWithPair_t { _ _ }.
Arguments structWithPair_p { _ _ }.

(** [no_nested_borrows::new_pair1]:
    Source: 'src/no_nested_borrows.rs', lines 454:0-454:46 *)
Definition new_pair1 : result (StructWithPair_t u32 u32) :=
  Return {| structWithPair_p := {| pair_x := 1%u32; pair_y := 2%u32 |} |}
.

(** [no_nested_borrows::test_constants]:
    Source: 'src/no_nested_borrows.rs', lines 462:0-462:23 *)
Definition test_constants : result unit :=
  swt <- new_tuple1;
  let (i, _) := swt.(structWithTuple_p) in
  if negb (i s= 1%u32)
  then Fail_ Failure
  else (
    swt1 <- new_tuple2;
    let (i1, _) := swt1.(structWithTuple_p) in
    if negb (i1 s= 1%i16)
    then Fail_ Failure
    else (
      swt2 <- new_tuple3;
      let (i2, _) := swt2.(structWithTuple_p) in
      if negb (i2 s= 1%u64)
      then Fail_ Failure
      else (
        swp <- new_pair1;
        if negb (swp.(structWithPair_p).(pair_x) s= 1%u32)
        then Fail_ Failure
        else Return tt)))
.

(** Unit test for [no_nested_borrows::test_constants] *)
Check (test_constants )%return.

(** [no_nested_borrows::test_weird_borrows1]:
    Source: 'src/no_nested_borrows.rs', lines 471:0-471:28 *)
Definition test_weird_borrows1 : result unit :=
  Return tt.

(** Unit test for [no_nested_borrows::test_weird_borrows1] *)
Check (test_weird_borrows1 )%return.

(** [no_nested_borrows::test_mem_replace]:
    Source: 'src/no_nested_borrows.rs', lines 481:0-481:37 *)
Definition test_mem_replace (px : u32) : result u32 :=
  let (y, _) := core_mem_replace u32 px 1%u32 in
  if negb (y s= 0%u32) then Fail_ Failure else Return 2%u32
.

(** [no_nested_borrows::test_shared_borrow_bool1]:
    Source: 'src/no_nested_borrows.rs', lines 488:0-488:47 *)
Definition test_shared_borrow_bool1 (b : bool) : result u32 :=
  if b then Return 0%u32 else Return 1%u32
.

(** [no_nested_borrows::test_shared_borrow_bool2]:
    Source: 'src/no_nested_borrows.rs', lines 501:0-501:40 *)
Definition test_shared_borrow_bool2 : result u32 :=
  Return 0%u32.

(** [no_nested_borrows::test_shared_borrow_enum1]:
    Source: 'src/no_nested_borrows.rs', lines 516:0-516:52 *)
Definition test_shared_borrow_enum1 (l : List_t u32) : result u32 :=
  match l with | List_Cons _ _ => Return 1%u32 | List_Nil => Return 0%u32 end
.

(** [no_nested_borrows::test_shared_borrow_enum2]:
    Source: 'src/no_nested_borrows.rs', lines 528:0-528:40 *)
Definition test_shared_borrow_enum2 : result u32 :=
  Return 0%u32.

(** [no_nested_borrows::incr]:
    Source: 'src/no_nested_borrows.rs', lines 539:0-539:24 *)
Definition incr (x : u32) : result u32 :=
  u32_add x 1%u32.

(** [no_nested_borrows::call_incr]:
    Source: 'src/no_nested_borrows.rs', lines 543:0-543:35 *)
Definition call_incr (x : u32) : result u32 :=
  incr x.

(** [no_nested_borrows::read_then_incr]:
    Source: 'src/no_nested_borrows.rs', lines 548:0-548:41 *)
Definition read_then_incr (x : u32) : result (u32 * u32) :=
  x1 <- u32_add x 1%u32; Return (x, x1)
.

(** [no_nested_borrows::Tuple]
    Source: 'src/no_nested_borrows.rs', lines 554:0-554:24 *)
Definition Tuple_t (T1 T2 : Type) : Type := T1 * T2.

(** [no_nested_borrows::use_tuple_struct]:
    Source: 'src/no_nested_borrows.rs', lines 556:0-556:48 *)
Definition use_tuple_struct (x : Tuple_t u32 u32) : result (Tuple_t u32 u32) :=
  let (_, i) := x in Return (1%u32, i)
.

(** [no_nested_borrows::create_tuple_struct]:
    Source: 'src/no_nested_borrows.rs', lines 560:0-560:61 *)
Definition create_tuple_struct
  (x : u32) (y : u64) : result (Tuple_t u32 u64) :=
  Return (x, y)
.

(** [no_nested_borrows::IdType]
    Source: 'src/no_nested_borrows.rs', lines 565:0-565:20 *)
Definition IdType_t (T : Type) : Type := T.

(** [no_nested_borrows::use_id_type]:
    Source: 'src/no_nested_borrows.rs', lines 567:0-567:40 *)
Definition use_id_type (T : Type) (x : IdType_t T) : result T :=
  Return x.

(** [no_nested_borrows::create_id_type]:
    Source: 'src/no_nested_borrows.rs', lines 571:0-571:43 *)
Definition create_id_type (T : Type) (x : T) : result (IdType_t T) :=
  Return x.

End NoNestedBorrows.
