include Stdlib.String

let is_space = function ' ' | '\012' | '\n' | '\r' | '\t' -> true | _ -> false

let matches_at s i sub =
  let n = length sub in
  let rec go j =
    j = n || (unsafe_get s (i + j) = unsafe_get sub j && go (j + 1))
  in
  i + n <= length s && go 0

let find_sub ?(start = 0) ~sub s =
  if start < 0 || start > length s then invalid_arg "String.find_sub";
  let last = length s - length sub in
  let rec go i =
    if i > last then None else if matches_at s i sub then Some i else go (i + 1)
  in
  go start

let contains_sub ~sub s = Option.is_some (find_sub ~sub s)

(* Indices of non-overlapping occurrences of [sub], left to right. *)
let occurrences ~fn ~sub s =
  if sub = "" then invalid_arg fn;
  let n = length sub in
  let rec go start acc =
    match find_sub ~start ~sub s with
    | Some i when i + n <= length s -> go (i + n) (i :: acc)
    | _ -> List.rev acc
  in
  go 0 []

let split_on ~sep s =
  let n = length sep in
  let idx = occurrences ~fn:"String.split_on" ~sub:sep s in
  let rec go start acc = function
    | [] -> List.rev (sub s start (length s - start) :: acc)
    | i :: rest -> go (i + n) (sub s start (i - start) :: acc) rest
  in
  go 0 [] idx

let replace_all ~sub ~by s =
  match occurrences ~fn:"String.replace_all" ~sub s with
  | [] -> s
  | idx ->
      let b = Buffer.create (length s) in
      let n = length sub in
      let last =
        List.fold_left
          (fun start i ->
            Buffer.add_substring b s start (i - start);
            Buffer.add_string b by;
            i + n)
          0 idx
      in
      Buffer.add_substring b s last (length s - last);
      Buffer.contents b

let pad_left ?(c = ' ') n s =
  let len = length s in
  if len >= n then s else make (n - len) c ^ s

let pad_right ?(c = ' ') n s =
  let len = length s in
  if len >= n then s else s ^ make (n - len) c

let trim_left s =
  let len = length s in
  let rec go i =
    if i < len && is_space (unsafe_get s i) then go (i + 1) else i
  in
  let i = go 0 in
  if i = 0 then s else sub s i (len - i)

let trim_right s =
  let len = length s in
  let rec go i =
    if i > 0 && is_space (unsafe_get s (i - 1)) then go (i - 1) else i
  in
  let j = go len in
  if j = len then s else sub s 0 j

let chop_prefix ~prefix s =
  if starts_with ~prefix s then
    Some (sub s (length prefix) (length s - length prefix))
  else None

let chop_suffix ~suffix s =
  if ends_with ~suffix s then Some (sub s 0 (length s - length suffix))
  else None

let lines s =
  if s = "" then []
  else
    let parts = split_on_char '\n' s in
    let parts =
      if ends_with ~suffix:"\n" s then List.rev (List.tl (List.rev parts))
      else parts
    in
    List.map
      (fun l -> match chop_suffix ~suffix:"\r" l with Some l -> l | None -> l)
      parts

let is_blank s = for_all is_space s
