[@@@ochk.allow "SL002"]

module SM = Map.Make (String)

let a = SM.empty = SM.singleton "k" 1
