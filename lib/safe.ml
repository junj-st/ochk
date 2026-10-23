[@@@ostd.allow "SL003"] (* Poly is the deliberate escape hatch. *)

let ( = ) : int -> int -> bool = Stdlib.( = )
let ( <> ) : int -> int -> bool = Stdlib.( <> )
let ( < ) : int -> int -> bool = Stdlib.( < )
let ( > ) : int -> int -> bool = Stdlib.( > )
let ( <= ) : int -> int -> bool = Stdlib.( <= )
let ( >= ) : int -> int -> bool = Stdlib.( >= )
let compare = Int.compare
let equal = Int.equal
let min = Int.min
let max = Int.max

module Poly = struct
  let ( = ) = Stdlib.( = )
  let ( <> ) = Stdlib.( <> )
  let ( < ) = Stdlib.( < )
  let ( > ) = Stdlib.( > )
  let ( <= ) = Stdlib.( <= )
  let ( >= ) = Stdlib.( >= )
  let compare = Stdlib.compare
  let equal = Stdlib.( = )
  let min = Stdlib.min
  let max = Stdlib.max
end
