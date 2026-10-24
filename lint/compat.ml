(* Everything here depends on compiler-libs internals that change between
   OCaml releases. Keep version-specific code in this file (and classify.ml)
   so supporting a new compiler means touching as little as possible.
   Written against OCaml 5.3. *)

open Types

(* A compiler-version-independent view of the type shapes the classifier
   cares about. *)
type shape =
  | Arrow of type_expr  (** argument type *)
  | Tuple of type_expr list
  | Constr of Path.t * type_expr list
  | Var
  | Poly of type_expr
  | Object
  | Package
  | Poly_variant of type_expr list  (** argument types of present tags *)
  | Other

let view (ty : type_expr) : shape =
  match get_desc ty with
  | Tarrow (_, arg, _, _) -> Arrow arg
  | Ttuple ts -> Tuple ts
  | Tconstr (p, args, _) -> Constr (p, args)
  | Tvar _ | Tunivar _ -> Var
  | Tpoly (t, _) -> Poly t
  | Tobject _ -> Object
  | Tpackage _ -> Package
  | Tvariant row ->
      let args =
        List.concat_map
          (fun (_, f) ->
            match row_field_repr f with
            | Rpresent (Some t) -> [ t ]
            | Reither (_, ts, _) -> ts
            | Rpresent None | Rabsent -> [])
          (row_fields row)
      in
      Poly_variant args
  | Tlink _ | Tsubst _ | Tfield _ | Tnil -> Other

(* Field / argument types of a type declaration, before parameter
   substitution. [None] means abstract (no manifest, no representation). *)
type decl_shape =
  | Abstract_decl
  | Manifest of type_expr
  | Fields of type_expr list
  | Open_decl

let decl_shape (d : type_declaration) : decl_shape =
  match (d.type_kind, d.type_manifest) with
  | Type_abstract _, None -> Abstract_decl
  | Type_abstract _, Some m -> Manifest m
  | Type_record (labels, _), _ -> Fields (List.map (fun l -> l.ld_type) labels)
  | Type_variant (cstrs, _), _ ->
      Fields
        (List.concat_map
           (fun c ->
             match c.cd_args with
             | Cstr_tuple ts -> ts
             | Cstr_record labels -> List.map (fun l -> l.ld_type) labels)
           cstrs)
  | Type_open, _ -> Open_decl

(* The directory the compiler ran in. Release builds ([dune build -p])
   record the placeholder "/workspace_root", so when the recorded directory
   is missing, walk up from the .cmt file to the first directory containing
   the source file it was compiled from. *)
let build_root ~cmt_file (cmt : Cmt_format.cmt_infos) =
  if Sys.file_exists cmt.cmt_builddir then cmt.cmt_builddir
  else
    let rec up dir rel =
      if Sys.file_exists (Filename.concat dir rel) then Some dir
      else
        let parent = Filename.dirname dir in
        if parent = dir then None else up parent rel
    in
    let start = Filename.dirname cmt_file in
    match cmt.cmt_sourcefile with
    | Some src when Filename.is_relative src -> (
        match up start src with Some d -> d | None -> Sys.getcwd ())
    | _ -> Sys.getcwd ()

let init_load_path ~root (cmt : Cmt_format.cmt_infos) =
  let resolve dir =
    if Filename.is_relative dir then
      let in_root = Filename.concat root dir in
      if Sys.file_exists in_root then in_root else dir
    else dir
  in
  let { Load_path.visible; hidden } = cmt.cmt_loadpath in
  Load_path.init ~auto_include:Load_path.no_auto_include
    ~visible:(List.map resolve visible @ [ Config.standard_library ])
    ~hidden:(List.map resolve hidden)

(* The string payload of [[@attr "..."]], [Some ""] for no payload, [None]
   for anything else. *)
let string_payload (p : Parsetree.payload) : string option =
  match p with
  | PStr [] -> Some ""
  | PStr
      [
        {
          pstr_desc =
            Pstr_eval
              ( {
                  pexp_desc =
                    Pexp_constant { pconst_desc = Pconst_string (s, _, _); _ };
                  _;
                },
                _ );
          _;
        };
      ] ->
      Some s
  | _ -> None

(* [find_type_in_sig sg ["M"; "N"; "t"]]: the declaration of [M.N.t] in
   [sg], following nested module signatures. *)
let rec find_type_in_sig (sg : Types.signature) comps :
    Types.type_declaration option =
  match comps with
  | [] -> None
  | [ name ] ->
      List.find_map
        (function
          | Types.Sig_type (id, d, _, _) when Ident.name id = name -> Some d
          | _ -> None)
        sg
  | m :: rest ->
      List.find_map
        (function
          | Types.Sig_module (id, _, md, _, _) when Ident.name id = m -> (
              match md.md_type with
              | Mty_signature sg -> find_type_in_sig sg rest
              | _ -> None)
          | _ -> None)
        sg

(* The signature a module expression really has, before any [: S]
   constraint hides it, and the environment its types live in. *)
let rec unconstrained (me : Typedtree.module_expr) =
  match me.mod_desc with
  | Tmod_constraint (inner, _, _, _) -> unconstrained inner
  | Tmod_structure s -> (s.str_type, s.str_final_env)
  | _ -> (
      match me.mod_type with
      | Mty_signature sg -> (sg, me.mod_env)
      | _ -> ([], me.mod_env))
