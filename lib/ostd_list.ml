include Stdlib.List

let split_at n l =
  if n < 0 then invalid_arg "List.split_at";
  let rec go n acc = function
    | x :: rest when n > 0 -> go (n - 1) (x :: acc) rest
    | rest -> (rev acc, rest)
  in
  go n [] l

let chunks n l =
  if n <= 0 then invalid_arg "List.chunks";
  let rec go acc = function
    | [] -> rev acc
    | l ->
        let chunk, rest = split_at n l in
        go (chunk :: acc) rest
  in
  go [] l

let windows n l =
  if n <= 0 then invalid_arg "List.windows";
  let rec go acc len l =
    if len < n then rev acc
    else
      match l with
      | [] -> rev acc
      | _ :: rest -> go (take n l :: acc) (len - 1) rest
  in
  go [] (length l) l

let group_by eq l =
  let rec go groups current = function
    | [] -> (
        match current with [] -> rev groups | _ -> rev (rev current :: groups))
    | x :: rest -> (
        match current with
        | prev :: _ when eq prev x -> go groups (x :: current) rest
        | [] -> go groups [ x ] rest
        | _ -> go (rev current :: groups) [ x ] rest)
  in
  go [] [] l

let rec last_opt = function
  | [] -> None
  | [ x ] -> Some x
  | _ :: rest -> last_opt rest

let last l =
  match last_opt l with Some x -> x | None -> invalid_arg "List.last"

let sum l = fold_left ( + ) 0 l

let sum_float l =
  let sum, _ =
    fold_left
      (fun (sum, c) x ->
        let y = x -. c in
        let t = sum +. y in
        (t, t -. sum -. y))
      (0., 0.) l
  in
  sum

let best_by keep = function
  | [] -> None
  | x :: rest ->
      Some (fold_left (fun best y -> if keep y best then y else best) x rest)

let max_by ~compare l = best_by (fun y best -> compare y best > 0) l
let min_by ~compare l = best_by (fun y best -> compare y best < 0) l

let dedup (type a) ~(compare : a -> a -> int) (l : a list) =
  let module S = Stdlib.Set.Make (struct
    type t = a

    let compare = compare
  end) in
  let _, acc =
    fold_left
      (fun (seen, acc) x ->
        if S.mem x seen then (seen, acc) else (S.add x seen, x :: acc))
      (S.empty, []) l
  in
  rev acc

let index_of ~eq x l = find_index (eq x) l
