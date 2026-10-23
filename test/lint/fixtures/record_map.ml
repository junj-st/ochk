module SM = Map.Make (String)

type portfolio = { owner : string; positions : int SM.t }

let p = { owner = "a"; positions = SM.empty }
let same = p = { p with owner = "b" }
