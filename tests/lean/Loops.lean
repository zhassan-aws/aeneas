-- THIS FILE WAS AUTOMATICALLY GENERATED BY AENEAS
-- [loops]
import Base
open Primitives

namespace loops

/- [loops::sum]: loop 0:
   Source: 'src/loops.rs', lines 4:0-14:1 -/
divergent def sum_loop (max : U32) (i : U32) (s : U32) : Result U32 :=
  if i < max
  then do
       let s1 ← s + i
       let i1 ← i + 1#u32
       sum_loop max i1 s1
  else s * 2#u32

/- [loops::sum]:
   Source: 'src/loops.rs', lines 4:0-4:27 -/
def sum (max : U32) : Result U32 :=
  sum_loop max 0#u32 0#u32

/- [loops::sum_with_mut_borrows]: loop 0:
   Source: 'src/loops.rs', lines 19:0-31:1 -/
divergent def sum_with_mut_borrows_loop
  (max : U32) (mi : U32) (ms : U32) : Result U32 :=
  if mi < max
  then
    do
    let ms1 ← ms + mi
    let mi1 ← mi + 1#u32
    sum_with_mut_borrows_loop max mi1 ms1
  else ms * 2#u32

/- [loops::sum_with_mut_borrows]:
   Source: 'src/loops.rs', lines 19:0-19:44 -/
def sum_with_mut_borrows (max : U32) : Result U32 :=
  sum_with_mut_borrows_loop max 0#u32 0#u32

/- [loops::sum_with_shared_borrows]: loop 0:
   Source: 'src/loops.rs', lines 34:0-48:1 -/
divergent def sum_with_shared_borrows_loop
  (max : U32) (i : U32) (s : U32) : Result U32 :=
  if i < max
  then
    do
    let i1 ← i + 1#u32
    let s1 ← s + i1
    sum_with_shared_borrows_loop max i1 s1
  else s * 2#u32

/- [loops::sum_with_shared_borrows]:
   Source: 'src/loops.rs', lines 34:0-34:47 -/
def sum_with_shared_borrows (max : U32) : Result U32 :=
  sum_with_shared_borrows_loop max 0#u32 0#u32

/- [loops::sum_array]: loop 0:
   Source: 'src/loops.rs', lines 50:0-58:1 -/
divergent def sum_array_loop
  (N : Usize) (a : Array U32 N) (i : Usize) (s : U32) : Result U32 :=
  if i < N
  then
    do
    let i1 ← Array.index_usize U32 N a i
    let s1 ← s + i1
    let i2 ← i + 1#usize
    sum_array_loop N a i2 s1
  else Result.ret s

/- [loops::sum_array]:
   Source: 'src/loops.rs', lines 50:0-50:52 -/
def sum_array (N : Usize) (a : Array U32 N) : Result U32 :=
  sum_array_loop N a 0#usize 0#u32

/- [loops::clear]: loop 0:
   Source: 'src/loops.rs', lines 62:0-68:1 -/
divergent def clear_loop
  (v : alloc.vec.Vec U32) (i : Usize) : Result (alloc.vec.Vec U32) :=
  let i1 := alloc.vec.Vec.len U32 v
  if i < i1
  then
    do
    let (_, index_mut_back) ←
      alloc.vec.Vec.index_mut U32 Usize
        (core.slice.index.SliceIndexUsizeSliceTInst U32) v i
    let i2 ← i + 1#usize
    let v1 ← index_mut_back 0#u32
    clear_loop v1 i2
  else Result.ret v

/- [loops::clear]:
   Source: 'src/loops.rs', lines 62:0-62:30 -/
def clear (v : alloc.vec.Vec U32) : Result (alloc.vec.Vec U32) :=
  clear_loop v 0#usize

/- [loops::List]
   Source: 'src/loops.rs', lines 70:0-70:16 -/
inductive List (T : Type) :=
| Cons : T → List T → List T
| Nil : List T

/- [loops::list_mem]: loop 0:
   Source: 'src/loops.rs', lines 76:0-85:1 -/
divergent def list_mem_loop (x : U32) (ls : List U32) : Result Bool :=
  match ls with
  | List.Cons y tl => if y = x
                      then Result.ret true
                      else list_mem_loop x tl
  | List.Nil => Result.ret false

/- [loops::list_mem]:
   Source: 'src/loops.rs', lines 76:0-76:52 -/
def list_mem (x : U32) (ls : List U32) : Result Bool :=
  list_mem_loop x ls

/- [loops::list_nth_mut_loop]: loop 0:
   Source: 'src/loops.rs', lines 88:0-98:1 -/
divergent def list_nth_mut_loop_loop
  (T : Type) (ls : List T) (i : U32) : Result (T × (T → Result (List T))) :=
  match ls with
  | List.Cons x tl =>
    if i = 0#u32
    then
      let back := fun ret => Result.ret (List.Cons ret tl)
      Result.ret (x, back)
    else
      do
      let i1 ← i - 1#u32
      let (t, back) ← list_nth_mut_loop_loop T tl i1
      let back1 :=
        fun ret => do
                   let tl1 ← back ret
                   Result.ret (List.Cons x tl1)
      Result.ret (t, back1)
  | List.Nil => Result.fail .panic

/- [loops::list_nth_mut_loop]:
   Source: 'src/loops.rs', lines 88:0-88:71 -/
def list_nth_mut_loop
  (T : Type) (ls : List T) (i : U32) : Result (T × (T → Result (List T))) :=
  do
  let (t, back) ← list_nth_mut_loop_loop T ls i
  Result.ret (t, back)

/- [loops::list_nth_shared_loop]: loop 0:
   Source: 'src/loops.rs', lines 101:0-111:1 -/
divergent def list_nth_shared_loop_loop
  (T : Type) (ls : List T) (i : U32) : Result T :=
  match ls with
  | List.Cons x tl =>
    if i = 0#u32
    then Result.ret x
    else do
         let i1 ← i - 1#u32
         list_nth_shared_loop_loop T tl i1
  | List.Nil => Result.fail .panic

/- [loops::list_nth_shared_loop]:
   Source: 'src/loops.rs', lines 101:0-101:66 -/
def list_nth_shared_loop (T : Type) (ls : List T) (i : U32) : Result T :=
  list_nth_shared_loop_loop T ls i

/- [loops::get_elem_mut]: loop 0:
   Source: 'src/loops.rs', lines 113:0-127:1 -/
divergent def get_elem_mut_loop
  (x : Usize) (ls : List Usize) :
  Result (Usize × (Usize → Result (List Usize)))
  :=
  match ls with
  | List.Cons y tl =>
    if y = x
    then
      let back := fun ret => Result.ret (List.Cons ret tl)
      Result.ret (y, back)
    else
      do
      let (i, back) ← get_elem_mut_loop x tl
      let back1 :=
        fun ret => do
                   let tl1 ← back ret
                   Result.ret (List.Cons y tl1)
      Result.ret (i, back1)
  | List.Nil => Result.fail .panic

/- [loops::get_elem_mut]:
   Source: 'src/loops.rs', lines 113:0-113:73 -/
def get_elem_mut
  (slots : alloc.vec.Vec (List Usize)) (x : Usize) :
  Result (Usize × (Usize → Result (alloc.vec.Vec (List Usize))))
  :=
  do
  let (l, index_mut_back) ←
    alloc.vec.Vec.index_mut (List Usize) Usize
      (core.slice.index.SliceIndexUsizeSliceTInst (List Usize)) slots 0#usize
  let (i, back) ← get_elem_mut_loop x l
  let back1 := fun ret => do
                          let l1 ← back ret
                          index_mut_back l1
  Result.ret (i, back1)

/- [loops::get_elem_shared]: loop 0:
   Source: 'src/loops.rs', lines 129:0-143:1 -/
divergent def get_elem_shared_loop
  (x : Usize) (ls : List Usize) : Result Usize :=
  match ls with
  | List.Cons y tl => if y = x
                      then Result.ret y
                      else get_elem_shared_loop x tl
  | List.Nil => Result.fail .panic

/- [loops::get_elem_shared]:
   Source: 'src/loops.rs', lines 129:0-129:68 -/
def get_elem_shared
  (slots : alloc.vec.Vec (List Usize)) (x : Usize) : Result Usize :=
  do
  let l ←
    alloc.vec.Vec.index (List Usize) Usize
      (core.slice.index.SliceIndexUsizeSliceTInst (List Usize)) slots 0#usize
  get_elem_shared_loop x l

/- [loops::id_mut]:
   Source: 'src/loops.rs', lines 145:0-145:50 -/
def id_mut
  (T : Type) (ls : List T) :
  Result ((List T) × (List T → Result (List T)))
  :=
  Result.ret (ls, Result.ret)

/- [loops::id_shared]:
   Source: 'src/loops.rs', lines 149:0-149:45 -/
def id_shared (T : Type) (ls : List T) : Result (List T) :=
  Result.ret ls

/- [loops::list_nth_mut_loop_with_id]: loop 0:
   Source: 'src/loops.rs', lines 154:0-165:1 -/
divergent def list_nth_mut_loop_with_id_loop
  (T : Type) (i : U32) (ls : List T) : Result (T × (T → Result (List T))) :=
  match ls with
  | List.Cons x tl =>
    if i = 0#u32
    then
      let back := fun ret => Result.ret (List.Cons ret tl)
      Result.ret (x, back)
    else
      do
      let i1 ← i - 1#u32
      let (t, back) ← list_nth_mut_loop_with_id_loop T i1 tl
      let back1 :=
        fun ret => do
                   let tl1 ← back ret
                   Result.ret (List.Cons x tl1)
      Result.ret (t, back1)
  | List.Nil => Result.fail .panic

/- [loops::list_nth_mut_loop_with_id]:
   Source: 'src/loops.rs', lines 154:0-154:75 -/
def list_nth_mut_loop_with_id
  (T : Type) (ls : List T) (i : U32) : Result (T × (T → Result (List T))) :=
  do
  let (ls1, id_mut_back) ← id_mut T ls
  let (t, back) ← list_nth_mut_loop_with_id_loop T i ls1
  let back1 := fun ret => do
                          let l ← back ret
                          id_mut_back l
  Result.ret (t, back1)

/- [loops::list_nth_shared_loop_with_id]: loop 0:
   Source: 'src/loops.rs', lines 168:0-179:1 -/
divergent def list_nth_shared_loop_with_id_loop
  (T : Type) (i : U32) (ls : List T) : Result T :=
  match ls with
  | List.Cons x tl =>
    if i = 0#u32
    then Result.ret x
    else do
         let i1 ← i - 1#u32
         list_nth_shared_loop_with_id_loop T i1 tl
  | List.Nil => Result.fail .panic

/- [loops::list_nth_shared_loop_with_id]:
   Source: 'src/loops.rs', lines 168:0-168:70 -/
def list_nth_shared_loop_with_id
  (T : Type) (ls : List T) (i : U32) : Result T :=
  do
  let ls1 ← id_shared T ls
  list_nth_shared_loop_with_id_loop T i ls1

/- [loops::list_nth_mut_loop_pair]: loop 0:
   Source: 'src/loops.rs', lines 184:0-205:1 -/
divergent def list_nth_mut_loop_pair_loop
  (T : Type) (ls0 : List T) (ls1 : List T) (i : U32) :
  Result ((T × T) × (T → Result (List T)) × (T → Result (List T)))
  :=
  match ls0 with
  | List.Cons x0 tl0 =>
    match ls1 with
    | List.Cons x1 tl1 =>
      if i = 0#u32
      then
        let back_'a := fun ret => Result.ret (List.Cons ret tl0)
        let back_'b := fun ret => Result.ret (List.Cons ret tl1)
        Result.ret ((x0, x1), back_'a, back_'b)
      else
        do
        let i1 ← i - 1#u32
        let (p, back_'a, back_'b) ← list_nth_mut_loop_pair_loop T tl0 tl1 i1
        let back_'a1 :=
          fun ret => do
                     let tl01 ← back_'a ret
                     Result.ret (List.Cons x0 tl01)
        let back_'b1 :=
          fun ret => do
                     let tl11 ← back_'b ret
                     Result.ret (List.Cons x1 tl11)
        Result.ret (p, back_'a1, back_'b1)
    | List.Nil => Result.fail .panic
  | List.Nil => Result.fail .panic

/- [loops::list_nth_mut_loop_pair]:
   Source: 'src/loops.rs', lines 184:0-188:27 -/
def list_nth_mut_loop_pair
  (T : Type) (ls0 : List T) (ls1 : List T) (i : U32) :
  Result ((T × T) × (T → Result (List T)) × (T → Result (List T)))
  :=
  do
  let (p, back_'a, back_'b) ← list_nth_mut_loop_pair_loop T ls0 ls1 i
  Result.ret (p, back_'a, back_'b)

/- [loops::list_nth_shared_loop_pair]: loop 0:
   Source: 'src/loops.rs', lines 208:0-229:1 -/
divergent def list_nth_shared_loop_pair_loop
  (T : Type) (ls0 : List T) (ls1 : List T) (i : U32) : Result (T × T) :=
  match ls0 with
  | List.Cons x0 tl0 =>
    match ls1 with
    | List.Cons x1 tl1 =>
      if i = 0#u32
      then Result.ret (x0, x1)
      else do
           let i1 ← i - 1#u32
           list_nth_shared_loop_pair_loop T tl0 tl1 i1
    | List.Nil => Result.fail .panic
  | List.Nil => Result.fail .panic

/- [loops::list_nth_shared_loop_pair]:
   Source: 'src/loops.rs', lines 208:0-212:19 -/
def list_nth_shared_loop_pair
  (T : Type) (ls0 : List T) (ls1 : List T) (i : U32) : Result (T × T) :=
  list_nth_shared_loop_pair_loop T ls0 ls1 i

/- [loops::list_nth_mut_loop_pair_merge]: loop 0:
   Source: 'src/loops.rs', lines 233:0-248:1 -/
divergent def list_nth_mut_loop_pair_merge_loop
  (T : Type) (ls0 : List T) (ls1 : List T) (i : U32) :
  Result ((T × T) × ((T × T) → Result ((List T) × (List T))))
  :=
  match ls0 with
  | List.Cons x0 tl0 =>
    match ls1 with
    | List.Cons x1 tl1 =>
      if i = 0#u32
      then
        let back_'a :=
          fun ret =>
            let (t, t1) := ret
            Result.ret (List.Cons t tl0, List.Cons t1 tl1)
        Result.ret ((x0, x1), back_'a)
      else
        do
        let i1 ← i - 1#u32
        let (p, back_'a) ← list_nth_mut_loop_pair_merge_loop T tl0 tl1 i1
        let back_'a1 :=
          fun ret =>
            do
            let (tl01, tl11) ← back_'a ret
            Result.ret (List.Cons x0 tl01, List.Cons x1 tl11)
        Result.ret (p, back_'a1)
    | List.Nil => Result.fail .panic
  | List.Nil => Result.fail .panic

/- [loops::list_nth_mut_loop_pair_merge]:
   Source: 'src/loops.rs', lines 233:0-237:27 -/
def list_nth_mut_loop_pair_merge
  (T : Type) (ls0 : List T) (ls1 : List T) (i : U32) :
  Result ((T × T) × ((T × T) → Result ((List T) × (List T))))
  :=
  do
  let (p, back_'a) ← list_nth_mut_loop_pair_merge_loop T ls0 ls1 i
  Result.ret (p, back_'a)

/- [loops::list_nth_shared_loop_pair_merge]: loop 0:
   Source: 'src/loops.rs', lines 251:0-266:1 -/
divergent def list_nth_shared_loop_pair_merge_loop
  (T : Type) (ls0 : List T) (ls1 : List T) (i : U32) : Result (T × T) :=
  match ls0 with
  | List.Cons x0 tl0 =>
    match ls1 with
    | List.Cons x1 tl1 =>
      if i = 0#u32
      then Result.ret (x0, x1)
      else
        do
        let i1 ← i - 1#u32
        list_nth_shared_loop_pair_merge_loop T tl0 tl1 i1
    | List.Nil => Result.fail .panic
  | List.Nil => Result.fail .panic

/- [loops::list_nth_shared_loop_pair_merge]:
   Source: 'src/loops.rs', lines 251:0-255:19 -/
def list_nth_shared_loop_pair_merge
  (T : Type) (ls0 : List T) (ls1 : List T) (i : U32) : Result (T × T) :=
  list_nth_shared_loop_pair_merge_loop T ls0 ls1 i

/- [loops::list_nth_mut_shared_loop_pair]: loop 0:
   Source: 'src/loops.rs', lines 269:0-284:1 -/
divergent def list_nth_mut_shared_loop_pair_loop
  (T : Type) (ls0 : List T) (ls1 : List T) (i : U32) :
  Result ((T × T) × (T → Result (List T)))
  :=
  match ls0 with
  | List.Cons x0 tl0 =>
    match ls1 with
    | List.Cons x1 tl1 =>
      if i = 0#u32
      then
        let back_'a := fun ret => Result.ret (List.Cons ret tl0)
        Result.ret ((x0, x1), back_'a)
      else
        do
        let i1 ← i - 1#u32
        let (p, back_'a) ← list_nth_mut_shared_loop_pair_loop T tl0 tl1 i1
        let back_'a1 :=
          fun ret => do
                     let tl01 ← back_'a ret
                     Result.ret (List.Cons x0 tl01)
        Result.ret (p, back_'a1)
    | List.Nil => Result.fail .panic
  | List.Nil => Result.fail .panic

/- [loops::list_nth_mut_shared_loop_pair]:
   Source: 'src/loops.rs', lines 269:0-273:23 -/
def list_nth_mut_shared_loop_pair
  (T : Type) (ls0 : List T) (ls1 : List T) (i : U32) :
  Result ((T × T) × (T → Result (List T)))
  :=
  do
  let (p, back_'a) ← list_nth_mut_shared_loop_pair_loop T ls0 ls1 i
  Result.ret (p, back_'a)

/- [loops::list_nth_mut_shared_loop_pair_merge]: loop 0:
   Source: 'src/loops.rs', lines 288:0-303:1 -/
divergent def list_nth_mut_shared_loop_pair_merge_loop
  (T : Type) (ls0 : List T) (ls1 : List T) (i : U32) :
  Result ((T × T) × (T → Result (List T)))
  :=
  match ls0 with
  | List.Cons x0 tl0 =>
    match ls1 with
    | List.Cons x1 tl1 =>
      if i = 0#u32
      then
        let back_'a := fun ret => Result.ret (List.Cons ret tl0)
        Result.ret ((x0, x1), back_'a)
      else
        do
        let i1 ← i - 1#u32
        let (p, back_'a) ←
          list_nth_mut_shared_loop_pair_merge_loop T tl0 tl1 i1
        let back_'a1 :=
          fun ret => do
                     let tl01 ← back_'a ret
                     Result.ret (List.Cons x0 tl01)
        Result.ret (p, back_'a1)
    | List.Nil => Result.fail .panic
  | List.Nil => Result.fail .panic

/- [loops::list_nth_mut_shared_loop_pair_merge]:
   Source: 'src/loops.rs', lines 288:0-292:23 -/
def list_nth_mut_shared_loop_pair_merge
  (T : Type) (ls0 : List T) (ls1 : List T) (i : U32) :
  Result ((T × T) × (T → Result (List T)))
  :=
  do
  let (p, back_'a) ← list_nth_mut_shared_loop_pair_merge_loop T ls0 ls1 i
  Result.ret (p, back_'a)

/- [loops::list_nth_shared_mut_loop_pair]: loop 0:
   Source: 'src/loops.rs', lines 307:0-322:1 -/
divergent def list_nth_shared_mut_loop_pair_loop
  (T : Type) (ls0 : List T) (ls1 : List T) (i : U32) :
  Result ((T × T) × (T → Result (List T)))
  :=
  match ls0 with
  | List.Cons x0 tl0 =>
    match ls1 with
    | List.Cons x1 tl1 =>
      if i = 0#u32
      then
        let back_'b := fun ret => Result.ret (List.Cons ret tl1)
        Result.ret ((x0, x1), back_'b)
      else
        do
        let i1 ← i - 1#u32
        let (p, back_'b) ← list_nth_shared_mut_loop_pair_loop T tl0 tl1 i1
        let back_'b1 :=
          fun ret => do
                     let tl11 ← back_'b ret
                     Result.ret (List.Cons x1 tl11)
        Result.ret (p, back_'b1)
    | List.Nil => Result.fail .panic
  | List.Nil => Result.fail .panic

/- [loops::list_nth_shared_mut_loop_pair]:
   Source: 'src/loops.rs', lines 307:0-311:23 -/
def list_nth_shared_mut_loop_pair
  (T : Type) (ls0 : List T) (ls1 : List T) (i : U32) :
  Result ((T × T) × (T → Result (List T)))
  :=
  do
  let (p, back_'b) ← list_nth_shared_mut_loop_pair_loop T ls0 ls1 i
  Result.ret (p, back_'b)

/- [loops::list_nth_shared_mut_loop_pair_merge]: loop 0:
   Source: 'src/loops.rs', lines 326:0-341:1 -/
divergent def list_nth_shared_mut_loop_pair_merge_loop
  (T : Type) (ls0 : List T) (ls1 : List T) (i : U32) :
  Result ((T × T) × (T → Result (List T)))
  :=
  match ls0 with
  | List.Cons x0 tl0 =>
    match ls1 with
    | List.Cons x1 tl1 =>
      if i = 0#u32
      then
        let back_'a := fun ret => Result.ret (List.Cons ret tl1)
        Result.ret ((x0, x1), back_'a)
      else
        do
        let i1 ← i - 1#u32
        let (p, back_'a) ←
          list_nth_shared_mut_loop_pair_merge_loop T tl0 tl1 i1
        let back_'a1 :=
          fun ret => do
                     let tl11 ← back_'a ret
                     Result.ret (List.Cons x1 tl11)
        Result.ret (p, back_'a1)
    | List.Nil => Result.fail .panic
  | List.Nil => Result.fail .panic

/- [loops::list_nth_shared_mut_loop_pair_merge]:
   Source: 'src/loops.rs', lines 326:0-330:23 -/
def list_nth_shared_mut_loop_pair_merge
  (T : Type) (ls0 : List T) (ls1 : List T) (i : U32) :
  Result ((T × T) × (T → Result (List T)))
  :=
  do
  let (p, back_'a) ← list_nth_shared_mut_loop_pair_merge_loop T ls0 ls1 i
  Result.ret (p, back_'a)

end loops
