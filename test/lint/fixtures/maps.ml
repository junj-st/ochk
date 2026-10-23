module SM = Map.Make (String)

let a = SM.singleton "k" 1
let fine = SM.equal Int.equal a a
let bad_map = a = SM.empty
let h : (string, int) Hashtbl.t = Hashtbl.create 16
let bad_tbl = compare h (Hashtbl.copy h)
