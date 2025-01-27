-- THIS FILE WAS AUTOMATICALLY GENERATED BY AENEAS
-- [external]: function definitions
import Base
import External.Types
import External.FunsExternal
open Primitives

namespace external

/- [external::swap]:
   Source: 'src/external.rs', lines 6:0-6:46 -/
def swap
  (T : Type) (x : T) (y : T) (st : State) : Result (State × (T × T)) :=
  core.mem.swap T x y st

/- [external::test_new_non_zero_u32]:
   Source: 'src/external.rs', lines 11:0-11:60 -/
def test_new_non_zero_u32
  (x : U32) (st : State) : Result (State × core.num.nonzero.NonZeroU32) :=
  do
  let (st1, o) ← core.num.nonzero.NonZeroU32.new x st
  core.option.Option.unwrap core.num.nonzero.NonZeroU32 o st1

/- [external::test_vec]:
   Source: 'src/external.rs', lines 17:0-17:17 -/
def test_vec : Result Unit :=
  do
  let _ ← alloc.vec.Vec.push U32 (alloc.vec.Vec.new U32) 0#u32
  Result.ret ()

/- Unit test for [external::test_vec] -/
#assert (test_vec == Result.ret ())

/- [external::custom_swap]:
   Source: 'src/external.rs', lines 24:0-24:66 -/
def custom_swap
  (T : Type) (x : T) (y : T) (st : State) :
  Result (State × (T × (T → State → Result (State × (T × T)))))
  :=
  do
  let (st1, (t, t1)) ← core.mem.swap T x y st
  let back_'a := fun ret st2 => Result.ret (st2, (ret, t1))
  Result.ret (st1, (t, back_'a))

/- [external::test_custom_swap]:
   Source: 'src/external.rs', lines 29:0-29:59 -/
def test_custom_swap
  (x : U32) (y : U32) (st : State) : Result (State × (U32 × U32)) :=
  do
  let (st1, (_, custom_swap_back)) ← custom_swap U32 x y st
  let (_, (x1, y1)) ← custom_swap_back 1#u32 st1
  Result.ret (st1, (x1, y1))

/- [external::test_swap_non_zero]:
   Source: 'src/external.rs', lines 35:0-35:44 -/
def test_swap_non_zero (x : U32) (st : State) : Result (State × U32) :=
  do
  let (st1, p) ← swap U32 x 0#u32 st
  let (x1, _) := p
  if x1 = 0#u32
  then Result.fail .panic
  else Result.ret (st1, x1)

end external
