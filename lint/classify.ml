(* Is it safe to compare values of a given type with polymorphic compare? *)

type verdict =
  | Safe
  | Generic  (** a type variable: generic code relying on polymorphic compare *)
  | Abstract of string  (** display name of the abstract type *)
  | Functional  (** contains closures: compare raises at runtime *)

let rank = function
  | Safe -> 0
  | Generic -> 1
  | Abstract _ -> 2
  | Functional -> 3

let worst a b = if rank b > rank a then b else a

let safe_builtins =
  Predef.
    [
      path_int;
      path_char;
      path_string;
      path_bytes;
      path_float;
      path_bool;
      path_unit;
      path_nativeint;
      path_int32;
      path_int64;
      path_floatarray;
      path_exn;
      path_extension_constructor;
    ]

(* Abstract in their .mli but represented by safe immediates. *)
let safe_named =
  [
    "Stdlib.Uchar.t";
    "Stdlib__Uchar.t";
    "Uchar.t";
    (* An int on Unix, a custom block with its own compare on Windows. *)
    "Unix.file_descr";
    "UnixLabels.file_descr";
  ]

let containers = Predef.[ path_list; path_option; path_array ]
let mem_path p l = List.exists (Path.same p) l
let max_depth = 64

(* Also drops dune's internal alias modules: "Re__.Cset.t" -> "Cset.t". *)
let display_path p =
  let name =
    match Targets.normalize (Path.name p) with
    | Some n -> n
    | None -> Path.name p
  in
  String.split_on_char '.' name
  |> List.filter (fun c -> not (String.ends_with ~suffix:"__" c))
  |> String.concat "."

(* Is the root module of [p] one of [ids]? ([Path.head] fails on functor
   applications such as [Map.Make(String).t].) *)
let rec root_in (p : Path.t) ids =
  match p with
  | Pident id -> List.exists (Ident.same id) ids
  | Pdot (p, _) | Pextra_ty (p, _) -> root_in p ids
  | Papply _ -> false

(* Verdicts for non-parameterized types, valid for one .cmt file. Only
   results computed without cutting a recursive cycle are stored, since a cut
   can under-report (see [cut_cycle]). *)
module Path_table = Hashtbl.Make (struct
  type t = Path.t

  let equal = Path.same
  let hash = Hashtbl.hash
end)

let memo : verdict Path_table.t = Path_table.create 256
let cut_cycle = ref false

(* Hard cap on work per comparison: large mutually recursive type
   definitions (e.g. odoc's) otherwise take exponential time. When it runs
   out the comparison is not reported. *)
exception Out_of_budget

let budget_per_check = 20_000
let budget = ref budget_per_check
let skipped = ref 0
let reset () = Path_table.reset memo

let rec classify_in ~generic_roots env visited depth ty =
  decr budget;
  if !budget <= 0 then raise Out_of_budget;
  if depth > max_depth then Safe
  else
    (* The name the user wrote (e.g. [SM.t]), before expansion turns it into
       [Map.Make(Stdlib__String).t]. *)
    let written =
      match Compat.view ty with Constr (p, _) -> Some p | _ -> None
    in
    let ty = try Ctype.expand_head env ty with _ -> ty in
    let recur = classify_in ~generic_roots env visited (depth + 1) in
    match Compat.view ty with
    | Arrow _ | Package -> Functional
    | Var -> Generic
    | Poly t -> recur t
    | Object -> Abstract "object"
    | Tuple ts | Poly_variant ts -> worst_of recur ts
    | Other -> Safe
    | Constr (p, args) ->
        if mem_path p safe_builtins || List.mem (Path.name p) safe_named then
          Safe
        else if Path.same p Predef.path_lazy_t then Abstract "Lazy.t"
        else if mem_path p containers then worst_of recur args
        else if List.exists (Path.same p) visited then (
          (* Recursive occurrence: the shape is already being checked, but
             the arguments may differ (e.g. [(int -> int) t t]). *)
          cut_cycle := true;
          worst_of recur args)
        else if args = [] && Path_table.mem memo p then Path_table.find memo p
        else
          let outer_cut = !cut_cycle in
          cut_cycle := false;
          let v =
            classify_decl ~generic_roots env visited depth written p args
          in
          if args = [] && not !cut_cycle then Path_table.replace memo p v;
          cut_cycle := outer_cut || !cut_cycle;
          v

and classify_decl ~generic_roots env visited depth written p args =
  match Env.find_type p env with
  | exception Not_found -> Safe (* unknown: avoid false positives *)
  | decl -> (
      let visited = p :: visited in
      let recur = classify_in ~generic_roots env visited (depth + 1) in
      let inst t = try Ctype.apply env decl.type_params t args with _ -> t in
      match Compat.decl_shape decl with
      | Abstract_decl
        when (match p with Pident _ -> true | _ -> false)
             || root_in p generic_roots ->
          (* A locally abstract type ([fun (type k) ...]) or a type
                     from a functor parameter ([T.t] in [Make (T : S)]):
                     type variables in disguise. *)
          Generic
      | Abstract_decl ->
          Abstract (display_path (Option.value written ~default:p))
      | Manifest m -> recur (inst m)
      | Fields ts -> worst_of recur (List.map inst ts)
      | Open_decl -> Safe)

and worst_of f ts =
  List.fold_left
    (fun acc t -> if acc = Functional then acc else worst acc (f t))
    Safe ts

let classify ?(generic_roots = []) (env : Env.t) (ty : Types.type_expr) :
    verdict =
  budget := budget_per_check;
  cut_cycle := false;
  try classify_in ~generic_roots env [] 0 ty
  with Out_of_budget ->
    incr skipped;
    Safe

(* The type of the first argument of a function type, if any. *)
let first_arg env ty =
  let ty = try Ctype.expand_head env ty with _ -> ty in
  match Compat.view ty with Arrow a -> Some a | _ -> None
