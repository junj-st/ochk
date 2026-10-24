(* Find the real definition behind an abstract type, so the classifier can
   tell an [int] hidden behind a signature from a [Map] hidden behind one.

   - Modules defined in the file being linted: their unconstrained
     signature, from the typed tree.
   - Other compilation units: their .cmt file, found on the load path
     (dune builds and installs .cmt files; so does Stdlib). *)

open Typedtree

(* Local modules of the current file: ident -> (signature, env). *)
let local_modules : (Ident.t * (Types.signature * Env.t)) list ref = ref []

let set_current (str : structure) =
  let acc = ref [] in
  let open Tast_iterator in
  let add (mb : module_binding) =
    match mb.mb_id with
    | Some id -> acc := (id, Compat.unconstrained mb.mb_expr) :: !acc
    | None -> ()
  in
  let iter =
    {
      default_iterator with
      structure_item =
        (fun self item ->
          (match item.str_desc with
          | Tstr_module mb -> add mb
          | Tstr_recmodule mbs -> List.iter add mbs
          | _ -> ());
          default_iterator.structure_item self item);
    }
  in
  iter.structure iter str;
  local_modules := !acc

(* Implementations of other units, read once per run. *)
let units : (string, (Types.signature * Env.t) option) Hashtbl.t =
  Hashtbl.create 64

let find_unit name =
  match Hashtbl.find_opt units name with
  | Some r -> r
  | None ->
      let r =
        try
          let file = Load_path.find_normalized (name ^ ".cmt") in
          match (Cmt_format.read_cmt file).cmt_annots with
          | Implementation s -> Some (s.str_type, s.str_final_env)
          | _ -> None
        with _ -> None
      in
      Hashtbl.replace units name r;
      r

(* [Pdot (Pdot (Pident A, "B"), "t")] -> [Some (A, ["B"; "t"])]. *)
let rec split (p : Path.t) =
  match p with
  | Pident id -> Some (id, [])
  | Pdot (p, s) -> Option.map (fun (id, l) -> (id, l @ [ s ])) (split p)
  | Papply _ | Pextra_ty _ -> None

let resolve env (p : Path.t) : (Types.type_declaration * Env.t) option =
  let p = try Env.normalize_type_path None env p with _ -> p in
  match split p with
  | None | Some (_, []) -> None
  | Some (head, comps) -> (
      let scope =
        if Ident.global head then find_unit (Ident.name head)
        else
          List.find_map
            (fun (id, m) -> if Ident.same id head then Some m else None)
            !local_modules
      in
      match scope with
      | None -> None
      | Some (sg, env') -> (
          match Compat.find_type_in_sig sg comps with
          | None -> None
          | Some d ->
              let env' = try Envaux.env_of_only_summary env' with _ -> env' in
              Some (d, env')))
