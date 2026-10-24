(* Abstract types: what matters is what they hide. *)
module Id : sig
  type t

  val make : int -> t
end = struct
  type t = int

  let make x = x
end

module Env : sig
  type t

  val empty : t
end = struct
  module M = Map.Make (String)

  type t = int M.t

  let empty = M.empty
end

module Callback : sig
  type t

  val v : t
end = struct
  type t = unit -> unit

  let v () = ()
end

let ids = Id.make 1 = Id.make 2
let envs = Env.empty = Env.empty
let cbs = Callback.v = Callback.v
