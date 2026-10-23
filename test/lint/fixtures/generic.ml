let mem x l = List.exists (( = ) x) l
let typed (x : int) l = List.exists (( = ) x) l
let make (type k) ?(hash = Hashtbl.hash) (x : k) = hash x

module Make (T : sig
  type t
end) =
struct
  let same (a : T.t) b = a = b
end
