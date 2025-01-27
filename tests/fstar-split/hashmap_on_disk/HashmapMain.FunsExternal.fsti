(** THIS FILE WAS AUTOMATICALLY GENERATED BY AENEAS *)
(** [hashmap_main]: external function declarations *)
module HashmapMain.FunsExternal
open Primitives
include HashmapMain.Types

#set-options "--z3rlimit 50 --fuel 1 --ifuel 1"

(** [hashmap_main::hashmap_utils::deserialize]: forward function
    Source: 'src/hashmap_utils.rs', lines 10:0-10:43 *)
val hashmap_utils_deserialize
  : state -> result (state & (hashmap_HashMap_t u64))

(** [hashmap_main::hashmap_utils::serialize]: forward function
    Source: 'src/hashmap_utils.rs', lines 5:0-5:42 *)
val hashmap_utils_serialize
  : hashmap_HashMap_t u64 -> state -> result (state & unit)

