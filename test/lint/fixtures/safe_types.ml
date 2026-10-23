type point = { x : int; y : int }
type shape = Circle of float | Rect of point * point

let a = 1 = 2
let b = "a" < "b"
let c = compare (1, "x", 'c') (2, "y", 'd')
let d = [ Some 1; None ] = []
let e = { x = 1; y = 2 } = { x = 1; y = 3 }
let f = max (Circle 1.0) (Rect ({ x = 0; y = 0 }, { x = 1; y = 1 }))
let g = List.mem 3 [ 1; 2; 3 ]
let h = List.sort compare [ 3; 1; 2 ]
let i = List.assoc "k" [ ("k", 1) ]
let j = Hashtbl.hash "key"
let k = ref 1 = ref 2
let l = Ok 1 = Error "e"
let m = Uchar.of_int 65 = Uchar.of_int 66
let n = [| 1. |] = [| 2. |]
let fs = [ succ ]
let o = None
let p = fs <> [] && o = None
let q = `A succ <> `B
