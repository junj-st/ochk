(* ostd-lint: flag polymorphic comparison on functions, abstract types and
   (optionally) type variables, by reading the .cmt files of a build. *)

open Typedtree

let allow_attr = "ostd.allow"

(* Rules suppressed by a list of attributes. *)
let allowed_by (attrs : Parsetree.attributes) : Report.rule list =
  List.concat_map
    (fun (a : Parsetree.attribute) ->
      if a.attr_name.txt <> allow_attr then []
      else
        match Compat.string_payload a.attr_payload with
        | Some "" -> Report.all_rules
        | Some s ->
            List.filter_map Report.rule_of_string (String.split_on_char ',' s)
        | None -> [])
    attrs

let type_to_string env ty =
  try
    Printtyp.wrap_printing_env ~error:false env (fun () ->
        Format.asprintf "%a" Printtyp.type_expr ty)
  with _ -> "?"

let value_exists env name =
  match Longident.unflatten (String.split_on_char '.' name) with
  | None -> false
  | Some lid -> (
      match Env.find_value_by_name lid env with
      | _ -> true
      | exception _ -> false)

let message env ~name ~verdict ~ty_str =
  match (verdict : Classify.verdict) with
  | Functional ->
      Some
        ( Report.SL001,
          Printf.sprintf
            "polymorphic %s on %s, which contains functions; this raises \
             Invalid_argument at runtime."
            name ty_str )
  | Abstract t ->
      let modname =
        match String.rindex_opt t '.' with
        | Some i -> String.sub t 0 i
        | None -> ""
      in
      let fn =
        if
          List.mem name
            [ "compare"; "(<)"; "(>)"; "(<=)"; "(>=)"; "min"; "max" ]
        then "compare"
        else "equal"
      in
      let candidate = modname ^ "." ^ fn in
      let hint =
        if
          modname <> ""
          && String.equal name "Hashtbl.hash" |> not
          && value_exists env candidate
        then Printf.sprintf "Use %s instead." candidate
        else "Compare it with a dedicated function instead."
      in
      Some
        ( Report.SL002,
          Printf.sprintf
            "polymorphic %s on %s; %s is abstract, so the result depends on \
             its internal representation. %s"
            name ty_str t hint )
  | Generic ->
      Some
        ( Report.SL003,
          Printf.sprintf
            "polymorphic %s on type variable %s; generic code relying on \
             polymorphic comparison. Take an equality or compare function as \
             an argument."
            name ty_str )
  | Safe -> None

(* A constant or a constructor without arguments: [[]], [None], [`A], [0]. *)
let is_constant (e : expression) =
  match e.exp_desc with
  | Texp_constant _ | Texp_construct (_, _, []) | Texp_variant (_, None) -> true
  | _ -> false

let lint_structure (str : structure) : Report.finding list =
  let findings = ref [] in
  let file_allowed =
    List.concat_map
      (fun item ->
        match item.str_desc with
        | Tstr_attribute a -> allowed_by [ a ]
        | _ -> [])
      str.str_items
  in
  let stack = ref [ file_allowed ] in
  let is_allowed rule = List.exists (List.mem rule) !stack in
  let with_attrs attrs f =
    match allowed_by attrs with
    | [] -> f ()
    | rules ->
        stack := rules :: !stack;
        Fun.protect ~finally:(fun () -> stack := List.tl !stack) f
  in
  let trivial = ref [] in
  let check_ident (e : expression) path =
    match Targets.find path with
    | None -> ()
    | Some name when not e.exp_loc.loc_ghost -> (
        let env =
          try Envaux.env_of_only_summary e.exp_env with _ -> e.exp_env
        in
        match Classify.first_arg env e.exp_type with
        | None -> ()
        | Some arg -> (
            let verdict = Classify.classify env arg in
            let ty_str = lazy (type_to_string env arg) in
            match verdict with
            | Safe -> ()
            | _ -> (
                match
                  message env ~name ~verdict ~ty_str:(Lazy.force ty_str)
                with
                | Some (rule, msg) when not (is_allowed rule) ->
                    let s = e.exp_loc.loc_start and en = e.exp_loc.loc_end in
                    findings :=
                      {
                        Report.file = s.pos_fname;
                        line = s.pos_lnum;
                        col_start = s.pos_cnum - s.pos_bol;
                        col_end =
                          (if en.pos_lnum = s.pos_lnum then
                             en.pos_cnum - en.pos_bol
                           else s.pos_cnum - s.pos_bol + 1);
                        rule;
                        message = msg;
                      }
                      :: !findings
                | _ -> ())))
    | Some _ -> ()
  in
  let open Tast_iterator in
  let iter =
    {
      default_iterator with
      expr =
        (fun self e ->
          with_attrs e.exp_attributes (fun () ->
              (match e.exp_desc with
              | Texp_ident (path, _, _) ->
                  if not (List.memq e !trivial) then check_ident e path
              | Texp_apply (fn, args)
                when List.exists
                       (function
                         | _, Some a -> is_constant a | _, None -> false)
                       args ->
                  (* [l <> []], [x = None]: comparing with a constant never
                     inspects the other value, so it is always safe. *)
                  trivial := fn :: !trivial
              | _ -> ());
              default_iterator.expr self e));
      value_binding =
        (fun self vb ->
          with_attrs vb.vb_attributes (fun () ->
              default_iterator.value_binding self vb));
    }
  in
  iter.structure iter str;
  !findings

exception Tool_error of string

let lint_cmt file : Report.finding list =
  let cmt =
    try Cmt_format.read_cmt file
    with e ->
      let reason =
        match e with
        | Cmi_format.Error (Wrong_version_interface _) ->
            "wrong compiler version"
        | Cmi_format.Error (Not_an_interface _) | Cmt_format.Error _ ->
            "not a .cmt file, or written by a different compiler version"
        | Cmi_format.Error (Corrupted_interface _) -> "corrupted file"
        | e -> Printexc.to_string e
      in
      raise
        (Tool_error
           (Printf.sprintf "%s: %s (ostd-lint was built with OCaml %s)" file
              reason Sys.ocaml_version))
  in
  match cmt.cmt_annots with
  | Implementation str ->
      Compat.init_load_path cmt;
      Envaux.reset_cache ();
      lint_structure str
  | _ -> []

(* All .cmt files under [path] (or [path] itself). *)
let rec find_cmts path acc =
  if Sys.is_directory path then
    Sys.readdir path |> Array.to_list |> List.sort String.compare
    |> List.fold_left (fun acc n -> find_cmts (Filename.concat path n) acc) acc
  else if Filename.check_suffix path ".cmt" then path :: acc
  else acc

type format = Text | Json

let () =
  let generic = ref false in
  let only = ref None in
  let format = ref Text in
  let paths = ref [] in
  let usage =
    "ostd-lint [--generic] [--only SL001,SL002] [--format text|json] [PATH...]\n\n\
     Reads .cmt files under each PATH (default: .) and reports polymorphic \
     comparison on functions (SL001), abstract types (SL002) and, with \
     --generic, type variables (SL003).\n\
     Exit codes: 0 = no findings, 1 = findings, 2 = tool error.\n"
  in
  let set_only s =
    let rules = String.split_on_char ',' s in
    match List.map Report.rule_of_string rules with
    | rs when List.for_all Option.is_some rs ->
        only := Some (List.filter_map Fun.id rs)
    | _ -> raise (Arg.Bad ("unknown rule in --only: " ^ s))
  in
  let specs =
    [
      ("--generic", Arg.Set generic, " Enable SL003 (compare-generic)");
      ( "--only",
        Arg.String set_only,
        "RULES Only report these comma-separated rules" );
      ( "--format",
        Arg.Symbol
          ( [ "text"; "json" ],
            fun s -> format := if s = "json" then Json else Text ),
        " Output format (default: text)" );
    ]
  in
  (try
     Arg.parse_argv Sys.argv (Arg.align specs)
       (fun p -> paths := p :: !paths)
       usage
   with
  | Arg.Help msg ->
      print_string msg;
      exit 0
  | Arg.Bad msg ->
      prerr_string msg;
      exit 2);
  let paths = match List.rev !paths with [] -> [ "." ] | ps -> ps in
  let enabled rule =
    match !only with
    | Some rules -> List.mem rule rules
    | None -> rule <> Report.SL003 || !generic
  in
  let errors = ref 0 in
  let findings =
    List.concat_map
      (fun path ->
        if not (Sys.file_exists path) then (
          Printf.eprintf "ostd-lint: %s: no such file or directory\n" path;
          incr errors;
          [])
        else
          List.concat_map
            (fun file ->
              try lint_cmt file with
              | Tool_error msg ->
                  Printf.eprintf "ostd-lint: %s\n" msg;
                  incr errors;
                  []
              | e ->
                  Printf.eprintf "ostd-lint: %s: internal error: %s\n" file
                    (Printexc.to_string e);
                  incr errors;
                  [])
            (List.rev (find_cmts path [])))
      paths
    |> List.filter (fun (f : Report.finding) -> enabled f.rule)
    |> Report.normalize
  in
  (match !format with
  | Text -> List.iter (Report.print_text stdout) findings
  | Json -> Report.print_json stdout findings);
  exit (if !errors > 0 then 2 else if findings <> [] then 1 else 0)
