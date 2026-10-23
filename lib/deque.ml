(* [front] holds the first elements in order; [back] holds the last elements
   in reverse order (head of [back] = last element). *)
type 'a t = { front : 'a list; flen : int; back : 'a list; blen : int }

let empty = { front = []; flen = 0; back = []; blen = 0 }
let is_empty d = d.flen + d.blen = 0
let length d = d.flen + d.blen
let push_front x d = { d with front = x :: d.front; flen = d.flen + 1 }
let push_back d x = { d with back = x :: d.back; blen = d.blen + 1 }

(* Move about half the elements of [l] (length [n]) to the other side.
   Returns (kept, moved): [kept] stays where it is, [moved] (in the other
   side's order) is the half nearest the other end. *)
let split_half l n =
  let keep = n / 2 in
  let kept, rest = Ostd_list.split_at keep l in
  (kept, keep, List.rev rest, n - keep)

let pop_front d =
  match d.front with
  | x :: front -> Some (x, { d with front; flen = d.flen - 1 })
  | [] -> (
      match d.back with
      | [] -> None
      | [ x ] -> Some (x, empty)
      | _ -> (
          let back, blen, front, flen = split_half d.back d.blen in
          match front with
          | x :: front -> Some (x, { front; flen = flen - 1; back; blen })
          | [] -> assert false))

let pop_back d =
  match d.back with
  | x :: back -> Some ({ d with back; blen = d.blen - 1 }, x)
  | [] -> (
      match d.front with
      | [] -> None
      | [ x ] -> Some (empty, x)
      | _ -> (
          let front, flen, back, blen = split_half d.front d.flen in
          match back with
          | x :: back -> Some ({ front; flen; back; blen = blen - 1 }, x)
          | [] -> assert false))

let peek_front d = Option.map fst (pop_front d)
let peek_back d = Option.map snd (pop_back d)
let of_list l = { front = l; flen = List.length l; back = []; blen = 0 }
let to_list d = d.front @ List.rev d.back
