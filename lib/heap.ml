module type OrderedType = sig
  type t

  val compare : t -> t -> int
end

module type S = sig
  type elt
  type t

  val empty : t
  val is_empty : t -> bool
  val size : t -> int
  val add : elt -> t -> t
  val merge : t -> t -> t
  val peek_min : t -> elt option
  val pop_min : t -> (elt * t) option
  val of_list : elt list -> t
  val to_sorted_list : t -> elt list
end

module Make (Ord : OrderedType) = struct
  type elt = Ord.t
  type tree = Leaf | Node of elt * tree list
  type t = { size : int; tree : tree }

  let empty = { size = 0; tree = Leaf }
  let is_empty h = h.size = 0
  let size h = h.size

  let meld a b =
    match (a, b) with
    | Leaf, t | t, Leaf -> t
    | Node (x, xs), Node (y, ys) ->
        if Ord.compare x y <= 0 then Node (x, b :: xs) else Node (y, a :: ys)

  (* Standard two-pass pairing, written tail-recursively. *)
  let merge_pairs trees =
    let rec pair acc = function
      | a :: b :: rest -> pair (meld a b :: acc) rest
      | [ a ] -> a :: acc
      | [] -> acc
    in
    List.fold_left (fun acc t -> meld t acc) Leaf (pair [] trees)

  let merge h1 h2 = { size = h1.size + h2.size; tree = meld h1.tree h2.tree }
  let add x h = { size = h.size + 1; tree = meld (Node (x, [])) h.tree }
  let peek_min h = match h.tree with Leaf -> None | Node (x, _) -> Some x

  let pop_min h =
    match h.tree with
    | Leaf -> None
    | Node (x, children) ->
        Some (x, { size = h.size - 1; tree = merge_pairs children })

  let of_list l = List.fold_left (fun h x -> add x h) empty l

  let to_sorted_list h =
    let rec go acc h =
      match pop_min h with
      | None -> List.rev acc
      | Some (x, h) -> go (x :: acc) h
    in
    go [] h
end
