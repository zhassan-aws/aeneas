-- THIS FILE WAS AUTOMATICALLY GENERATED BY AENEAS
-- [paper]
import Base
open Primitives

namespace paper

/- [paper::ref_incr]:
   Source: 'src/paper.rs', lines 4:0-4:28 -/
def ref_incr (x : I32) : Result I32 :=
  x + 1#i32

/- [paper::test_incr]:
   Source: 'src/paper.rs', lines 8:0-8:18 -/
def test_incr : Result Unit :=
  do
  let i ← ref_incr 0#i32
  if not (i = 1#i32)
  then Result.fail .panic
  else Result.ret ()

/- Unit test for [paper::test_incr] -/
#assert (test_incr == Result.ret ())

/- [paper::choose]:
   Source: 'src/paper.rs', lines 15:0-15:70 -/
def choose
  (T : Type) (b : Bool) (x : T) (y : T) :
  Result (T × (T → Result (T × T)))
  :=
  if b
  then let back_'a := fun ret => Result.ret (ret, y)
       Result.ret (x, back_'a)
  else let back_'a := fun ret => Result.ret (x, ret)
       Result.ret (y, back_'a)

/- [paper::test_choose]:
   Source: 'src/paper.rs', lines 23:0-23:20 -/
def test_choose : Result Unit :=
  do
  let (z, choose_back) ← choose I32 true 0#i32 0#i32
  let z1 ← z + 1#i32
  if not (z1 = 1#i32)
  then Result.fail .panic
  else
    do
    let (x, y) ← choose_back z1
    if not (x = 1#i32)
    then Result.fail .panic
    else if not (y = 0#i32)
         then Result.fail .panic
         else Result.ret ()

/- Unit test for [paper::test_choose] -/
#assert (test_choose == Result.ret ())

/- [paper::List]
   Source: 'src/paper.rs', lines 35:0-35:16 -/
inductive List (T : Type) :=
| Cons : T → List T → List T
| Nil : List T

/- [paper::list_nth_mut]:
   Source: 'src/paper.rs', lines 42:0-42:67 -/
divergent def list_nth_mut
  (T : Type) (l : List T) (i : U32) : Result (T × (T → Result (List T))) :=
  match l with
  | List.Cons x tl =>
    if i = 0#u32
    then
      let back_'a := fun ret => Result.ret (List.Cons ret tl)
      Result.ret (x, back_'a)
    else
      do
      let i1 ← i - 1#u32
      let (t, list_nth_mut_back) ← list_nth_mut T tl i1
      let back_'a :=
        fun ret =>
          do
          let tl1 ← list_nth_mut_back ret
          Result.ret (List.Cons x tl1)
      Result.ret (t, back_'a)
  | List.Nil => Result.fail .panic

/- [paper::sum]:
   Source: 'src/paper.rs', lines 57:0-57:32 -/
divergent def sum (l : List I32) : Result I32 :=
  match l with
  | List.Cons x tl => do
                      let i ← sum tl
                      x + i
  | List.Nil => Result.ret 0#i32

/- [paper::test_nth]:
   Source: 'src/paper.rs', lines 68:0-68:17 -/
def test_nth : Result Unit :=
  do
  let l := List.Cons 3#i32 List.Nil
  let l1 := List.Cons 2#i32 l
  let (x, list_nth_mut_back) ← list_nth_mut I32 (List.Cons 1#i32 l1) 2#u32
  let x1 ← x + 1#i32
  let l2 ← list_nth_mut_back x1
  let i ← sum l2
  if not (i = 7#i32)
  then Result.fail .panic
  else Result.ret ()

/- Unit test for [paper::test_nth] -/
#assert (test_nth == Result.ret ())

/- [paper::call_choose]:
   Source: 'src/paper.rs', lines 76:0-76:44 -/
def call_choose (p : (U32 × U32)) : Result U32 :=
  do
  let (px, py) := p
  let (pz, choose_back) ← choose U32 true px py
  let pz1 ← pz + 1#u32
  let (px1, _) ← choose_back pz1
  Result.ret px1

end paper
