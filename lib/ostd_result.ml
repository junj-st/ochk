include Stdlib.Result

let all rs =
  let rec go acc = function
    | [] -> Ok (Stdlib.List.rev acc)
    | Ok v :: rest -> go (v :: acc) rest
    | Error e :: _ -> Error e
  in
  go [] rs

module Syntax = struct
  let ( let* ) = bind
  let ( let+ ) r f = map f r

  let ( and* ) a b =
    match (a, b) with
    | Ok a, Ok b -> Ok (a, b)
    | Error e, _ | _, Error e -> Error e

  let ( and+ ) = ( and* )
end
