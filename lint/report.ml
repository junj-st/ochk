(* Rules, findings, and compiler-style / JSON output. *)

type rule = SL001 | SL002 | SL003 | SL004

let rule_id = function
  | SL001 -> "SL001"
  | SL002 -> "SL002"
  | SL003 -> "SL003"
  | SL004 -> "SL004"

let rule_name = function
  | SL001 -> "compare-functional"
  | SL002 -> "compare-abstract"
  | SL003 -> "compare-generic"
  | SL004 -> "compare-opaque"

let rule_of_string s =
  match String.uppercase_ascii (String.trim s) with
  | "SL001" -> Some SL001
  | "SL002" -> Some SL002
  | "SL003" -> Some SL003
  | "SL004" -> Some SL004
  | _ -> None

let all_rules = [ SL001; SL002; SL003; SL004 ]

type severity = Error | Warning

let severity = function SL001 -> Error | SL002 | SL003 | SL004 -> Warning
let severity_string = function Error -> "Error" | Warning -> "Warning"

type finding = {
  file : string;
  line : int;
  col_start : int;
  col_end : int;
  rule : rule;
  message : string;
}

let compare_finding a b =
  match String.compare a.file b.file with
  | 0 -> (
      match Int.compare a.line b.line with
      | 0 -> (
          match Int.compare a.col_start b.col_start with
          | 0 -> String.compare (rule_id a.rule) (rule_id b.rule)
          | c -> c)
      | c -> c)
  | c -> c

let same_finding a b = compare_finding a b = 0

(* Sorted, without duplicates (the same source can be seen through several
   .cmt files). *)
let normalize findings =
  List.sort compare_finding findings
  |> List.fold_left
       (fun acc f ->
         match acc with
         | prev :: _ when same_finding prev f -> acc
         | _ -> f :: acc)
       []
  |> List.rev

let print_text oc f =
  Printf.fprintf oc "File \"%s\", line %d, characters %d-%d:\n%s %s [%s]: %s\n"
    f.file f.line f.col_start f.col_end
    (severity_string (severity f.rule))
    (rule_id f.rule) (rule_name f.rule) f.message

let json_string s =
  let b = Buffer.create (String.length s + 2) in
  Buffer.add_char b '"';
  String.iter
    (function
      | '"' -> Buffer.add_string b "\\\""
      | '\\' -> Buffer.add_string b "\\\\"
      | '\n' -> Buffer.add_string b "\\n"
      | c when Char.code c < 0x20 -> Printf.bprintf b "\\u%04x" (Char.code c)
      | c -> Buffer.add_char b c)
    s;
  Buffer.add_char b '"';
  Buffer.contents b

let print_json oc findings =
  let item f =
    Printf.sprintf
      "{\"file\":%s,\"line\":%d,\"start\":%d,\"end\":%d,\"rule\":%s,\"name\":%s,\"severity\":%s,\"message\":%s}"
      (json_string f.file) f.line f.col_start f.col_end
      (json_string (rule_id f.rule))
      (json_string (rule_name f.rule))
      (json_string (String.lowercase_ascii (severity_string (severity f.rule))))
      (json_string f.message)
  in
  Printf.fprintf oc "[%s]\n" (String.concat ",\n " (List.map item findings))
