-- THIS FILE WAS AUTOMATICALLY GENERATED BY AENEAS
-- [hashmap]: function definitions
import Base
import Hashmap.Types
open Primitives

namespace hashmap

/- [hashmap::hash_key]: forward function -/
def hash_key (k : Usize) : Result Usize :=
  Result.ret k

/- [hashmap::HashMap::{0}::allocate_slots]: loop 0: forward function -/
divergent def HashMap.allocate_slots_loop
  (T : Type) (slots : alloc.vec.Vec (List T)) (n : Usize) :
  Result (alloc.vec.Vec (List T))
  :=
  if n > 0#usize
  then
    do
      let slots0 ← alloc.vec.Vec.push (List T) slots List.Nil
      let n0 ← n - 1#usize
      HashMap.allocate_slots_loop T slots0 n0
  else Result.ret slots

/- [hashmap::HashMap::{0}::allocate_slots]: forward function -/
def HashMap.allocate_slots
  (T : Type) (slots : alloc.vec.Vec (List T)) (n : Usize) :
  Result (alloc.vec.Vec (List T))
  :=
  HashMap.allocate_slots_loop T slots n

/- [hashmap::HashMap::{0}::new_with_capacity]: forward function -/
def HashMap.new_with_capacity
  (T : Type) (capacity : Usize) (max_load_dividend : Usize)
  (max_load_divisor : Usize) :
  Result (HashMap T)
  :=
  do
    let v := alloc.vec.Vec.new (List T)
    let slots ← HashMap.allocate_slots T v capacity
    let i ← capacity * max_load_dividend
    let i0 ← i / max_load_divisor
    Result.ret
      {
        num_entries := 0#usize,
        max_load_factor := (max_load_dividend, max_load_divisor),
        max_load := i0,
        slots := slots
      }

/- [hashmap::HashMap::{0}::new]: forward function -/
def HashMap.new (T : Type) : Result (HashMap T) :=
  HashMap.new_with_capacity T 32#usize 4#usize 5#usize

/- [hashmap::HashMap::{0}::clear]: loop 0: merged forward/backward function
   (there is a single backward function, and the forward function returns ()) -/
divergent def HashMap.clear_loop
  (T : Type) (slots : alloc.vec.Vec (List T)) (i : Usize) :
  Result (alloc.vec.Vec (List T))
  :=
  let i0 := alloc.vec.Vec.len (List T) slots
  if i < i0
  then
    do
      let i1 ← i + 1#usize
      let slots0 ←
        alloc.vec.Vec.index_mut_back (List T) Usize
          (core.slice.index.usize.coresliceindexSliceIndexInst (List T)) slots
          i List.Nil
      HashMap.clear_loop T slots0 i1
  else Result.ret slots

/- [hashmap::HashMap::{0}::clear]: merged forward/backward function
   (there is a single backward function, and the forward function returns ()) -/
def HashMap.clear (T : Type) (self : HashMap T) : Result (HashMap T) :=
  do
    let v ← HashMap.clear_loop T self.slots 0#usize
    Result.ret { self with num_entries := 0#usize, slots := v }

/- [hashmap::HashMap::{0}::len]: forward function -/
def HashMap.len (T : Type) (self : HashMap T) : Result Usize :=
  Result.ret self.num_entries

/- [hashmap::HashMap::{0}::insert_in_list]: loop 0: forward function -/
divergent def HashMap.insert_in_list_loop
  (T : Type) (key : Usize) (value : T) (ls : List T) : Result Bool :=
  match ls with
  | List.Cons ckey cvalue tl =>
    if ckey = key
    then Result.ret false
    else HashMap.insert_in_list_loop T key value tl
  | List.Nil => Result.ret true

/- [hashmap::HashMap::{0}::insert_in_list]: forward function -/
def HashMap.insert_in_list
  (T : Type) (key : Usize) (value : T) (ls : List T) : Result Bool :=
  HashMap.insert_in_list_loop T key value ls

/- [hashmap::HashMap::{0}::insert_in_list]: loop 0: backward function 0 -/
divergent def HashMap.insert_in_list_loop_back
  (T : Type) (key : Usize) (value : T) (ls : List T) : Result (List T) :=
  match ls with
  | List.Cons ckey cvalue tl =>
    if ckey = key
    then Result.ret (List.Cons ckey value tl)
    else
      do
        let tl0 ← HashMap.insert_in_list_loop_back T key value tl
        Result.ret (List.Cons ckey cvalue tl0)
  | List.Nil => let l := List.Nil
                Result.ret (List.Cons key value l)

/- [hashmap::HashMap::{0}::insert_in_list]: backward function 0 -/
def HashMap.insert_in_list_back
  (T : Type) (key : Usize) (value : T) (ls : List T) : Result (List T) :=
  HashMap.insert_in_list_loop_back T key value ls

/- [hashmap::HashMap::{0}::insert_no_resize]: merged forward/backward function
   (there is a single backward function, and the forward function returns ()) -/
def HashMap.insert_no_resize
  (T : Type) (self : HashMap T) (key : Usize) (value : T) :
  Result (HashMap T)
  :=
  do
    let hash ← hash_key key
    let i := alloc.vec.Vec.len (List T) self.slots
    let hash_mod ← hash % i
    let l ←
      alloc.vec.Vec.index_mut (List T) Usize
        (core.slice.index.usize.coresliceindexSliceIndexInst (List T))
        self.slots hash_mod
    let inserted ← HashMap.insert_in_list T key value l
    if inserted
    then
      do
        let i0 ← self.num_entries + 1#usize
        let l0 ← HashMap.insert_in_list_back T key value l
        let v ←
          alloc.vec.Vec.index_mut_back (List T) Usize
            (core.slice.index.usize.coresliceindexSliceIndexInst (List T))
            self.slots hash_mod l0
        Result.ret { self with num_entries := i0, slots := v }
    else
      do
        let l0 ← HashMap.insert_in_list_back T key value l
        let v ←
          alloc.vec.Vec.index_mut_back (List T) Usize
            (core.slice.index.usize.coresliceindexSliceIndexInst (List T))
            self.slots hash_mod l0
        Result.ret { self with slots := v }

/- [hashmap::HashMap::{0}::move_elements_from_list]: loop 0: merged forward/backward function
   (there is a single backward function, and the forward function returns ()) -/
divergent def HashMap.move_elements_from_list_loop
  (T : Type) (ntable : HashMap T) (ls : List T) : Result (HashMap T) :=
  match ls with
  | List.Cons k v tl =>
    do
      let ntable0 ← HashMap.insert_no_resize T ntable k v
      HashMap.move_elements_from_list_loop T ntable0 tl
  | List.Nil => Result.ret ntable

/- [hashmap::HashMap::{0}::move_elements_from_list]: merged forward/backward function
   (there is a single backward function, and the forward function returns ()) -/
def HashMap.move_elements_from_list
  (T : Type) (ntable : HashMap T) (ls : List T) : Result (HashMap T) :=
  HashMap.move_elements_from_list_loop T ntable ls

/- [hashmap::HashMap::{0}::move_elements]: loop 0: merged forward/backward function
   (there is a single backward function, and the forward function returns ()) -/
divergent def HashMap.move_elements_loop
  (T : Type) (ntable : HashMap T) (slots : alloc.vec.Vec (List T)) (i : Usize)
  :
  Result ((HashMap T) × (alloc.vec.Vec (List T)))
  :=
  let i0 := alloc.vec.Vec.len (List T) slots
  if i < i0
  then
    do
      let l ←
        alloc.vec.Vec.index_mut (List T) Usize
          (core.slice.index.usize.coresliceindexSliceIndexInst (List T)) slots
          i
      let ls := core.mem.replace (List T) l List.Nil
      let ntable0 ← HashMap.move_elements_from_list T ntable ls
      let i1 ← i + 1#usize
      let l0 := core.mem.replace_back (List T) l List.Nil
      let slots0 ←
        alloc.vec.Vec.index_mut_back (List T) Usize
          (core.slice.index.usize.coresliceindexSliceIndexInst (List T)) slots
          i l0
      HashMap.move_elements_loop T ntable0 slots0 i1
  else Result.ret (ntable, slots)

/- [hashmap::HashMap::{0}::move_elements]: merged forward/backward function
   (there is a single backward function, and the forward function returns ()) -/
def HashMap.move_elements
  (T : Type) (ntable : HashMap T) (slots : alloc.vec.Vec (List T)) (i : Usize)
  :
  Result ((HashMap T) × (alloc.vec.Vec (List T)))
  :=
  HashMap.move_elements_loop T ntable slots i

/- [hashmap::HashMap::{0}::try_resize]: merged forward/backward function
   (there is a single backward function, and the forward function returns ()) -/
def HashMap.try_resize (T : Type) (self : HashMap T) : Result (HashMap T) :=
  do
    let max_usize ← Scalar.cast .Usize core_u32_max
    let capacity := alloc.vec.Vec.len (List T) self.slots
    let n1 ← max_usize / 2#usize
    let (i, i0) := self.max_load_factor
    let i1 ← n1 / i
    if capacity <= i1
    then
      do
        let i2 ← capacity * 2#usize
        let ntable ← HashMap.new_with_capacity T i2 i i0
        let (ntable0, _) ← HashMap.move_elements T ntable self.slots 0#usize
        Result.ret
          {
            ntable0
              with
              num_entries := self.num_entries, max_load_factor := (i, i0)
          }
    else Result.ret { self with max_load_factor := (i, i0) }

/- [hashmap::HashMap::{0}::insert]: merged forward/backward function
   (there is a single backward function, and the forward function returns ()) -/
def HashMap.insert
  (T : Type) (self : HashMap T) (key : Usize) (value : T) :
  Result (HashMap T)
  :=
  do
    let self0 ← HashMap.insert_no_resize T self key value
    let i ← HashMap.len T self0
    if i > self0.max_load
    then HashMap.try_resize T self0
    else Result.ret self0

/- [hashmap::HashMap::{0}::contains_key_in_list]: loop 0: forward function -/
divergent def HashMap.contains_key_in_list_loop
  (T : Type) (key : Usize) (ls : List T) : Result Bool :=
  match ls with
  | List.Cons ckey t tl =>
    if ckey = key
    then Result.ret true
    else HashMap.contains_key_in_list_loop T key tl
  | List.Nil => Result.ret false

/- [hashmap::HashMap::{0}::contains_key_in_list]: forward function -/
def HashMap.contains_key_in_list
  (T : Type) (key : Usize) (ls : List T) : Result Bool :=
  HashMap.contains_key_in_list_loop T key ls

/- [hashmap::HashMap::{0}::contains_key]: forward function -/
def HashMap.contains_key
  (T : Type) (self : HashMap T) (key : Usize) : Result Bool :=
  do
    let hash ← hash_key key
    let i := alloc.vec.Vec.len (List T) self.slots
    let hash_mod ← hash % i
    let l ←
      alloc.vec.Vec.index (List T) Usize
        (core.slice.index.usize.coresliceindexSliceIndexInst (List T))
        self.slots hash_mod
    HashMap.contains_key_in_list T key l

/- [hashmap::HashMap::{0}::get_in_list]: loop 0: forward function -/
divergent def HashMap.get_in_list_loop
  (T : Type) (key : Usize) (ls : List T) : Result T :=
  match ls with
  | List.Cons ckey cvalue tl =>
    if ckey = key
    then Result.ret cvalue
    else HashMap.get_in_list_loop T key tl
  | List.Nil => Result.fail Error.panic

/- [hashmap::HashMap::{0}::get_in_list]: forward function -/
def HashMap.get_in_list (T : Type) (key : Usize) (ls : List T) : Result T :=
  HashMap.get_in_list_loop T key ls

/- [hashmap::HashMap::{0}::get]: forward function -/
def HashMap.get (T : Type) (self : HashMap T) (key : Usize) : Result T :=
  do
    let hash ← hash_key key
    let i := alloc.vec.Vec.len (List T) self.slots
    let hash_mod ← hash % i
    let l ←
      alloc.vec.Vec.index (List T) Usize
        (core.slice.index.usize.coresliceindexSliceIndexInst (List T))
        self.slots hash_mod
    HashMap.get_in_list T key l

/- [hashmap::HashMap::{0}::get_mut_in_list]: loop 0: forward function -/
divergent def HashMap.get_mut_in_list_loop
  (T : Type) (ls : List T) (key : Usize) : Result T :=
  match ls with
  | List.Cons ckey cvalue tl =>
    if ckey = key
    then Result.ret cvalue
    else HashMap.get_mut_in_list_loop T tl key
  | List.Nil => Result.fail Error.panic

/- [hashmap::HashMap::{0}::get_mut_in_list]: forward function -/
def HashMap.get_mut_in_list
  (T : Type) (ls : List T) (key : Usize) : Result T :=
  HashMap.get_mut_in_list_loop T ls key

/- [hashmap::HashMap::{0}::get_mut_in_list]: loop 0: backward function 0 -/
divergent def HashMap.get_mut_in_list_loop_back
  (T : Type) (ls : List T) (key : Usize) (ret0 : T) : Result (List T) :=
  match ls with
  | List.Cons ckey cvalue tl =>
    if ckey = key
    then Result.ret (List.Cons ckey ret0 tl)
    else
      do
        let tl0 ← HashMap.get_mut_in_list_loop_back T tl key ret0
        Result.ret (List.Cons ckey cvalue tl0)
  | List.Nil => Result.fail Error.panic

/- [hashmap::HashMap::{0}::get_mut_in_list]: backward function 0 -/
def HashMap.get_mut_in_list_back
  (T : Type) (ls : List T) (key : Usize) (ret0 : T) : Result (List T) :=
  HashMap.get_mut_in_list_loop_back T ls key ret0

/- [hashmap::HashMap::{0}::get_mut]: forward function -/
def HashMap.get_mut (T : Type) (self : HashMap T) (key : Usize) : Result T :=
  do
    let hash ← hash_key key
    let i := alloc.vec.Vec.len (List T) self.slots
    let hash_mod ← hash % i
    let l ←
      alloc.vec.Vec.index_mut (List T) Usize
        (core.slice.index.usize.coresliceindexSliceIndexInst (List T))
        self.slots hash_mod
    HashMap.get_mut_in_list T l key

/- [hashmap::HashMap::{0}::get_mut]: backward function 0 -/
def HashMap.get_mut_back
  (T : Type) (self : HashMap T) (key : Usize) (ret0 : T) :
  Result (HashMap T)
  :=
  do
    let hash ← hash_key key
    let i := alloc.vec.Vec.len (List T) self.slots
    let hash_mod ← hash % i
    let l ←
      alloc.vec.Vec.index_mut (List T) Usize
        (core.slice.index.usize.coresliceindexSliceIndexInst (List T))
        self.slots hash_mod
    let l0 ← HashMap.get_mut_in_list_back T l key ret0
    let v ←
      alloc.vec.Vec.index_mut_back (List T) Usize
        (core.slice.index.usize.coresliceindexSliceIndexInst (List T))
        self.slots hash_mod l0
    Result.ret { self with slots := v }

/- [hashmap::HashMap::{0}::remove_from_list]: loop 0: forward function -/
divergent def HashMap.remove_from_list_loop
  (T : Type) (key : Usize) (ls : List T) : Result (Option T) :=
  match ls with
  | List.Cons ckey t tl =>
    if ckey = key
    then
      let mv_ls := core.mem.replace (List T) (List.Cons ckey t tl) List.Nil
      match mv_ls with
      | List.Cons i cvalue tl0 => Result.ret (some cvalue)
      | List.Nil => Result.fail Error.panic
    else HashMap.remove_from_list_loop T key tl
  | List.Nil => Result.ret none

/- [hashmap::HashMap::{0}::remove_from_list]: forward function -/
def HashMap.remove_from_list
  (T : Type) (key : Usize) (ls : List T) : Result (Option T) :=
  HashMap.remove_from_list_loop T key ls

/- [hashmap::HashMap::{0}::remove_from_list]: loop 0: backward function 1 -/
divergent def HashMap.remove_from_list_loop_back
  (T : Type) (key : Usize) (ls : List T) : Result (List T) :=
  match ls with
  | List.Cons ckey t tl =>
    if ckey = key
    then
      let mv_ls := core.mem.replace (List T) (List.Cons ckey t tl) List.Nil
      match mv_ls with
      | List.Cons i cvalue tl0 => Result.ret tl0
      | List.Nil => Result.fail Error.panic
    else
      do
        let tl0 ← HashMap.remove_from_list_loop_back T key tl
        Result.ret (List.Cons ckey t tl0)
  | List.Nil => Result.ret List.Nil

/- [hashmap::HashMap::{0}::remove_from_list]: backward function 1 -/
def HashMap.remove_from_list_back
  (T : Type) (key : Usize) (ls : List T) : Result (List T) :=
  HashMap.remove_from_list_loop_back T key ls

/- [hashmap::HashMap::{0}::remove]: forward function -/
def HashMap.remove
  (T : Type) (self : HashMap T) (key : Usize) : Result (Option T) :=
  do
    let hash ← hash_key key
    let i := alloc.vec.Vec.len (List T) self.slots
    let hash_mod ← hash % i
    let l ←
      alloc.vec.Vec.index_mut (List T) Usize
        (core.slice.index.usize.coresliceindexSliceIndexInst (List T))
        self.slots hash_mod
    let x ← HashMap.remove_from_list T key l
    match x with
    | none => Result.ret none
    | some x0 => do
                   let _ ← self.num_entries - 1#usize
                   Result.ret (some x0)

/- [hashmap::HashMap::{0}::remove]: backward function 0 -/
def HashMap.remove_back
  (T : Type) (self : HashMap T) (key : Usize) : Result (HashMap T) :=
  do
    let hash ← hash_key key
    let i := alloc.vec.Vec.len (List T) self.slots
    let hash_mod ← hash % i
    let l ←
      alloc.vec.Vec.index_mut (List T) Usize
        (core.slice.index.usize.coresliceindexSliceIndexInst (List T))
        self.slots hash_mod
    let x ← HashMap.remove_from_list T key l
    match x with
    | none =>
      do
        let l0 ← HashMap.remove_from_list_back T key l
        let v ←
          alloc.vec.Vec.index_mut_back (List T) Usize
            (core.slice.index.usize.coresliceindexSliceIndexInst (List T))
            self.slots hash_mod l0
        Result.ret { self with slots := v }
    | some x0 =>
      do
        let i0 ← self.num_entries - 1#usize
        let l0 ← HashMap.remove_from_list_back T key l
        let v ←
          alloc.vec.Vec.index_mut_back (List T) Usize
            (core.slice.index.usize.coresliceindexSliceIndexInst (List T))
            self.slots hash_mod l0
        Result.ret { self with num_entries := i0, slots := v }

/- [hashmap::test1]: forward function -/
def test1 : Result Unit :=
  do
    let hm ← HashMap.new U64
    let hm0 ← HashMap.insert U64 hm 0#usize 42#u64
    let hm1 ← HashMap.insert U64 hm0 128#usize 18#u64
    let hm2 ← HashMap.insert U64 hm1 1024#usize 138#u64
    let hm3 ← HashMap.insert U64 hm2 1056#usize 256#u64
    let i ← HashMap.get U64 hm3 128#usize
    if not (i = 18#u64)
    then Result.fail Error.panic
    else
      do
        let hm4 ← HashMap.get_mut_back U64 hm3 1024#usize 56#u64
        let i0 ← HashMap.get U64 hm4 1024#usize
        if not (i0 = 56#u64)
        then Result.fail Error.panic
        else
          do
            let x ← HashMap.remove U64 hm4 1024#usize
            match x with
            | none => Result.fail Error.panic
            | some x0 =>
              if not (x0 = 56#u64)
              then Result.fail Error.panic
              else
                do
                  let hm5 ← HashMap.remove_back U64 hm4 1024#usize
                  let i1 ← HashMap.get U64 hm5 0#usize
                  if not (i1 = 42#u64)
                  then Result.fail Error.panic
                  else
                    do
                      let i2 ← HashMap.get U64 hm5 128#usize
                      if not (i2 = 18#u64)
                      then Result.fail Error.panic
                      else
                        do
                          let i3 ← HashMap.get U64 hm5 1056#usize
                          if not (i3 = 256#u64)
                          then Result.fail Error.panic
                          else Result.ret ()

end hashmap
