let deep : (int -> int) list list = [ [ succ ] ]
let a = deep = deep
let o = Some (1, fun () -> ())
let b = o = o
let c = `A succ = `A pred
let s : int Seq.t = Seq.empty
let d = s = s

let obj =
  object
    method x = 1
  end

let e = obj = obj
let lz = lazy 1
let f = lz = lz

type a = X of b | Y of (int -> int)
and b = Z of a

let g = X (Z (Y succ)) = Y pred
let h = Z (Y succ) = Z (Y pred)
