(* Which identifiers count as polymorphic comparison. *)

let targets =
  [
    "=";
    "<>";
    "<";
    ">";
    "<=";
    ">=";
    "compare";
    "min";
    "max";
    "List.mem";
    "List.assoc";
    "List.assoc_opt";
    "List.mem_assoc";
    "List.remove_assoc";
    "Hashtbl.hash";
  ]

(* "Stdlib__List" -> "List", "Ostd__Ostd_list" / "Ostd_list" -> "List". *)
let normalize_component c =
  let strip_prefix ~prefix s =
    let n = String.length prefix in
    if String.length s > n && String.sub s 0 n = prefix then
      Some (String.sub s n (String.length s - n))
    else None
  in
  let c = Option.value ~default:c (strip_prefix ~prefix:"Stdlib__" c) in
  let c = Option.value ~default:c (strip_prefix ~prefix:"Ostd__" c) in
  match strip_prefix ~prefix:"Ostd_" c with
  | Some rest -> String.capitalize_ascii rest
  | None -> c

let is_root c =
  c = "Stdlib" || c = "Ostd"
  || String.starts_with ~prefix:"Stdlib__" c
  || String.starts_with ~prefix:"Ostd__" c

(* [normalize "Stdlib__List.mem"] = [Some "List.mem"]. Paths that do not
   start in Stdlib (or ostd, which re-exports it) are [None]: a user's own
   [compare] is not a target. *)
let normalize (name : string) : string option =
  match String.split_on_char '.' name with
  | root :: _ as comps when is_root root ->
      let comps =
        List.filter (fun c -> c <> "Stdlib" && c <> "Ostd") comps
        |> List.map normalize_component
        |> List.filter (fun c -> c <> "")
      in
      Some (String.concat "." comps)
  | _ -> None

(* Display name of a target, e.g. "(=)" or "List.mem". *)
let find (p : Path.t) : string option =
  match normalize (Path.name p) with
  | Some n when List.mem n targets ->
      let is_op =
        match n.[0] with 'a' .. 'z' | 'A' .. 'Z' -> false | _ -> true
      in
      Some (if is_op then "(" ^ n ^ ")" else n)
  | _ -> None
