open Ostd

let ints = Alcotest.(list int)

let raises_inv name f =
  Alcotest.check_raises name (Invalid_argument name) (fun () -> ignore (f ()))

let check_raises_any msg f =
  match f () with
  | _ -> Alcotest.failf "%s: expected Invalid_argument" msg
  | exception Invalid_argument _ -> ()

(* List *)
let list_tests =
  let open Alcotest in
  [
    test_case "split_at" `Quick (fun () ->
        check (pair ints ints) "mid"
          ([ 1 ], [ 2; 3 ])
          (List.split_at 1 [ 1; 2; 3 ]);
        check (pair ints ints) "over" ([ 1 ], []) (List.split_at 5 [ 1 ]);
        raises_inv "List.split_at" (fun () -> List.split_at (-1) [ 1 ]));
    test_case "take still from Stdlib" `Quick (fun () ->
        check ints "take" [ 1; 2 ] (List.take 2 [ 1; 2; 3 ]));
    test_case "chunks" `Quick (fun () ->
        check (list ints) "2" [ [ 1; 2 ]; [ 3 ] ] (List.chunks 2 [ 1; 2; 3 ]);
        check (list ints) "empty" [] (List.chunks 3 []);
        raises_inv "List.chunks" (fun () -> List.chunks 0 [ 1 ]));
    test_case "windows" `Quick (fun () ->
        check (list ints) "2"
          [ [ 1; 2 ]; [ 2; 3 ] ]
          (List.windows 2 [ 1; 2; 3 ]);
        check (list ints) "too short" [] (List.windows 4 [ 1; 2; 3 ]);
        check (list ints) "exact" [ [ 1; 2 ] ] (List.windows 2 [ 1; 2 ]);
        raises_inv "List.windows" (fun () -> List.windows 0 [ 1 ]));
    test_case "group_by" `Quick (fun () ->
        check (list ints) "runs"
          [ [ 1; 1 ]; [ 2 ]; [ 1 ] ]
          (List.group_by Int.equal [ 1; 1; 2; 1 ]);
        check (list ints) "empty" [] (List.group_by Int.equal []));
    test_case "last" `Quick (fun () ->
        check int "last" 3 (List.last [ 1; 2; 3 ]);
        check (option int) "last_opt" None (List.last_opt []);
        raises_inv "List.last" (fun () -> List.last []));
    test_case "sum" `Quick (fun () ->
        check int "sum" 6 (List.sum [ 1; 2; 3 ]);
        check int "sum []" 0 (List.sum []);
        check (float 1e-12) "kahan" 1.0
          (List.sum_float (List.init 10 (fun _ -> 0.1))));
    test_case "max_by/min_by" `Quick (fun () ->
        let by_len a b = Int.compare (String.length a) (String.length b) in
        check (option string) "max" (Some "ccc")
          (List.max_by ~compare:by_len [ "a"; "ccc"; "bb"; "ddd" ]);
        check (option string) "min first tie" (Some "a")
          (List.min_by ~compare:by_len [ "a"; "ccc"; "b" ]);
        check (option int) "empty" None (List.max_by ~compare:Int.compare []));
    test_case "dedup" `Quick (fun () ->
        check ints "stable" [ 3; 1; 2 ]
          (List.dedup ~compare:Int.compare [ 3; 1; 3; 2; 1 ]));
    test_case "index_of" `Quick (fun () ->
        check (option int) "found" (Some 1)
          (List.index_of ~eq:Int.equal 2 [ 1; 2; 2 ]);
        check (option int) "absent" None (List.index_of ~eq:Int.equal 9 [ 1 ]));
    test_case "large input is stack-safe" `Quick (fun () ->
        let l = List.init 1_000_000 Fun.id in
        check int "chunks" 1000 (List.length (List.chunks 1000 l));
        check int "dedup" 1_000_000
          (List.length (List.dedup ~compare:Int.compare l)));
  ]

(* String *)
let string_tests =
  let open Alcotest in
  let strs = list string in
  [
    test_case "split_on" `Quick (fun () ->
        check strs "ends" [ "a"; "b"; "" ] (String.split_on ~sep:", " "a, b, ");
        check strs "leading" [ ""; "a" ] (String.split_on ~sep:"--" "--a");
        check strs "empty input" [ "" ] (String.split_on ~sep:"x" "");
        check strs "non-overlapping" [ ""; "a" ]
          (String.split_on ~sep:"aa" "aaa");
        raises_inv "String.split_on" (fun () -> String.split_on ~sep:"" "abc"));
    test_case "replace_all" `Quick (fun () ->
        check string "basic" "xx" (String.replace_all ~sub:"ab" ~by:"x" "abab");
        check string "none" "hello"
          (String.replace_all ~sub:"z" ~by:"x" "hello");
        check string "grow" "a--b--c"
          (String.replace_all ~sub:"," ~by:"--" "a,b,c");
        raises_inv "String.replace_all" (fun () ->
            String.replace_all ~sub:"" ~by:"x" "abc"));
    test_case "find_sub/contains_sub" `Quick (fun () ->
        check (option int) "found" (Some 2) (String.find_sub ~sub:"cd" "abcd");
        check (option int) "start" (Some 4)
          (String.find_sub ~start:1 ~sub:"a" "abcda");
        check (option int) "empty sub" (Some 0) (String.find_sub ~sub:"" "abc");
        check (option int) "longer sub" None (String.find_sub ~sub:"abcd" "abc");
        check bool "contains" true (String.contains_sub ~sub:"bc" "abcd");
        check_raises_any "bad start" (fun () ->
            String.find_sub ~start:5 ~sub:"a" "abc"));
    test_case "pad" `Quick (fun () ->
        check string "left" "007" (String.pad_left ~c:'0' 3 "7");
        check string "no-op" "abc" (String.pad_left 1 "abc");
        check string "right" "ab  " (String.pad_right 4 "ab"));
    test_case "trim" `Quick (fun () ->
        check string "left" "a \n" (String.trim_left " \t a \n");
        check string "right" " \t a" (String.trim_right " \t a \n");
        check string "all blank" "" (String.trim_right "   "));
    test_case "chop" `Quick (fun () ->
        check (option string) "prefix" (Some "c")
          (String.chop_prefix ~prefix:"ab" "abc");
        check (option string) "no prefix" None
          (String.chop_prefix ~prefix:"x" "abc");
        check (option string) "suffix" (Some "a")
          (String.chop_suffix ~suffix:"bc" "abc"));
    test_case "lines" `Quick (fun () ->
        check strs "crlf" [ "a"; "b" ] (String.lines "a\r\nb\n");
        check strs "no final nl" [ "a"; ""; "b" ] (String.lines "a\n\nb");
        check strs "empty" [] (String.lines "");
        check strs "just nl" [ "" ] (String.lines "\n"));
    test_case "is_blank" `Quick (fun () ->
        check bool "ws" true (String.is_blank " \t\n");
        check bool "empty" true (String.is_blank "");
        check bool "text" false (String.is_blank " a "));
  ]

(* Option / Result *)
let option_result_tests =
  let open Alcotest in
  [
    test_case "Option.Syntax" `Quick (fun () ->
        let open Option.Syntax in
        check (option int) "both" (Some 3)
          (let+ x = Some 1 and+ y = Some 2 in
           x + y);
        check (option int) "none" None
          (let+ x = Some 1 and+ y = None in
           x + y);
        check (option int) "bind" (Some 2)
          (let* x = Some 1 in
           Some (x + 1)));
    test_case "Option.or_else" `Quick (fun () ->
        check (option int) "some" (Some 1)
          (Option.or_else (fun () -> Alcotest.fail "forced") (Some 1));
        check (option int) "none" (Some 2)
          (Option.or_else (fun () -> Some 2) None));
    test_case "Result.all" `Quick (fun () ->
        let r = result (list int) string in
        check r "ok" (Ok [ 1; 2 ]) (Result.all [ Ok 1; Ok 2 ]);
        check r "first error" (Error "a")
          (Result.all [ Ok 1; Error "a"; Error "b" ]);
        check r "empty" (Ok []) (Result.all []));
    test_case "Result.Syntax" `Quick (fun () ->
        let open Result.Syntax in
        let r = result int string in
        check r "ok" (Ok 3)
          (let+ x = Ok 1 and+ y = Ok 2 in
           x + y);
        check r "first err" (Error "x")
          (let+ x = Error "x" and+ y = Error "y" in
           x + y));
  ]

(* Map / Set *)
module SM = Map.Make (String)
module IS = Set.Make (Int)

let map_tests =
  let open Alcotest in
  let m = SM.of_list [ ("b", 2); ("a", 1) ] in
  [
    test_case "keys/values" `Quick (fun () ->
        check (list string) "keys" [ "a"; "b" ] (SM.keys m);
        check ints "values" [ 1; 2 ] (SM.values m));
    test_case "find_or/update_or" `Quick (fun () ->
        check int "missing" 0 (SM.find_or "z" ~default:0 m);
        let m =
          SM.update_or "z" ~default:0 succ m |> SM.update_or "a" ~default:0 succ
        in
        check int "new" 1 (SM.find "z" m);
        check int "existing" 2 (SM.find "a" m));
    test_case "merge_with" `Quick (fun () ->
        let m2 = SM.of_list [ ("b", 10); ("c", 3) ] in
        check
          (list (pair string int))
          "sum"
          [ ("a", 1); ("b", 12); ("c", 3) ]
          (SM.bindings (SM.merge_with (fun _ a b -> a + b) m m2)));
    test_case "group_by" `Quick (fun () ->
        let g = SM.group_by (fun s -> String.sub s 0 1) [ "ab"; "b"; "ac" ] in
        check
          (list (pair string (list string)))
          "groups"
          [ ("a", [ "ab"; "ac" ]); ("b", [ "b" ]) ]
          (SM.bindings g));
    test_case "interop with Stdlib.Map" `Quick (fun () ->
        let module Std = Stdlib.Map.Make (String) in
        let (s : int Std.t) = m in
        check int "same type" 2 (Std.cardinal s));
    test_case "Set.union_all" `Quick (fun () ->
        check ints "union" [ 1; 2; 3 ]
          (IS.elements
             (IS.union_all [ IS.of_list [ 1; 2 ]; IS.of_list [ 3 ]; IS.empty ]));
        check bool "empty" true (IS.is_empty (IS.union_all [])));
  ]

(* Heap / Deque *)
module IH = Heap.Make (Int)

let heap_deque_tests =
  let open Alcotest in
  [
    test_case "heap basics" `Quick (fun () ->
        check (option int) "empty peek" None (IH.peek_min IH.empty);
        let h = IH.of_list [ 5; 1; 3; 1 ] in
        check int "size" 4 (IH.size h);
        check (option int) "peek" (Some 1) (IH.peek_min h);
        check ints "sorted" [ 1; 1; 3; 5 ] (IH.to_sorted_list h);
        check ints "merge" [ 0; 1; 1; 3; 5; 9 ]
          (IH.to_sorted_list (IH.merge h (IH.of_list [ 9; 0 ])));
        check bool "persistent" true (IH.size h = 4));
    test_case "deque basics" `Quick (fun () ->
        let d = Deque.(push_back (push_front 0 (of_list [ 1; 2 ])) 3) in
        check ints "to_list" [ 0; 1; 2; 3 ] (Deque.to_list d);
        check (option int) "front" (Some 0) (Deque.peek_front d);
        check (option int) "back" (Some 3) (Deque.peek_back d);
        check bool "empty" true (Deque.pop_back Deque.empty = None));
  ]

(* Properties *)
type op = Push_front of int | Push_back of int | Pop_front | Pop_back

let op_gen =
  QCheck.Gen.(
    oneof
      [
        map (fun x -> Push_front x) nat_small;
        map (fun x -> Push_back x) nat_small;
        return Pop_front;
        return Pop_back;
      ])

let show_op = function
  | Push_front x -> Printf.sprintf "push_front %d" x
  | Push_back x -> Printf.sprintf "push_back %d" x
  | Pop_front -> "pop_front"
  | Pop_back -> "pop_back"

let props =
  [
    QCheck.Test.make ~name:"heap sorts like List.sort" ~count:500
      QCheck.(list int)
      (fun l -> IH.to_sorted_list (IH.of_list l) = List.sort Int.compare l);
    QCheck.Test.make ~name:"deque matches list model" ~count:500
      QCheck.(
        make
          ~print:(fun ops -> String.concat "; " (List.map show_op ops))
          Gen.(list op_gen))
      (fun ops ->
        let step (d, model) op =
          match op with
          | Push_front x -> (Deque.push_front x d, x :: model)
          | Push_back x -> (Deque.push_back d x, model @ [ x ])
          | Pop_front -> (
              match (Deque.pop_front d, model) with
              | None, [] -> (d, [])
              | Some (x, d), y :: model when x = y -> (d, model)
              | _ -> QCheck.Test.fail_report "pop_front mismatch")
          | Pop_back -> (
              match (Deque.pop_back d, List.rev model) with
              | None, [] -> (d, [])
              | Some (d, x), y :: rev when x = y -> (d, List.rev rev)
              | _ -> QCheck.Test.fail_report "pop_back mismatch")
        in
        let d, model = List.fold_left step (Deque.empty, []) ops in
        Deque.to_list d = model && Deque.length d = List.length model);
  ]

(* Safe *)
let safe_tests =
  let open Alcotest in
  [
    test_case "int ops and Poly" `Quick (fun () ->
        let open Safe in
        check bool "=" true (1 = 1);
        check int "max" 2 (max 1 2);
        check bool "poly" true (Poly.( = ) "a" "a"));
  ]

let () =
  Alcotest.run "ostd"
    [
      ("List", list_tests);
      ("String", string_tests);
      ("Option/Result", option_result_tests);
      ("Map/Set", map_tests);
      ("Heap/Deque", heap_deque_tests);
      ("properties", List.map QCheck_alcotest.to_alcotest props);
      ("Safe", safe_tests);
    ]
