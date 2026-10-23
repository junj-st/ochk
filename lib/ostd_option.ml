include Stdlib.Option

let or_else f = function Some _ as o -> o | None -> f ()

module Syntax = struct
  let ( let* ) = bind
  let ( let+ ) o f = map f o

  let ( and* ) a b =
    match (a, b) with Some a, Some b -> Some (a, b) | _ -> None

  let ( and+ ) = ( and* )
end
