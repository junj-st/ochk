include Stdlib.Map

module type S = sig
  include Stdlib.Map.S

  val keys : 'a t -> key list
  val values : 'a t -> 'a list
  val find_or : key -> default:'a -> 'a t -> 'a
  val update_or : key -> default:'a -> ('a -> 'a) -> 'a t -> 'a t
  val merge_with : (key -> 'a -> 'a -> 'a) -> 'a t -> 'a t -> 'a t
  val group_by : ('a -> key) -> 'a list -> 'a list t
end

module Make (Ord : OrderedType) = struct
  include Stdlib.Map.Make (Ord)

  let keys m = fold (fun k _ acc -> k :: acc) m [] |> Stdlib.List.rev
  let values m = fold (fun _ v acc -> v :: acc) m [] |> Stdlib.List.rev

  let find_or k ~default m =
    match find_opt k m with Some v -> v | None -> default

  let update_or k ~default f m =
    update k (function Some v -> Some (f v) | None -> Some (f default)) m

  let merge_with f m1 m2 = union (fun k a b -> Some (f k a b)) m1 m2

  let group_by key l =
    Stdlib.List.fold_left
      (fun m x -> update_or (key x) ~default:[] (fun xs -> x :: xs) m)
      empty l
    |> map Stdlib.List.rev
end
