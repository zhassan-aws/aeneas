(** THIS FILE WAS AUTOMATICALLY GENERATED BY AENEAS *)
(** [array]: type definitions *)
Require Import Primitives.
Import Primitives.
Require Import Coq.ZArith.ZArith.
Require Import List.
Import ListNotations.
Local Open Scope Primitives_scope.
Module Array_Types.

(** [array::T] *)
Inductive T_t := | TA : T_t | TB : T_t.

End Array_Types .