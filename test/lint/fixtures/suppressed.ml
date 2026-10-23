let f x = x + 1
let g x = x * 2
let a = (f = g) [@ostd.allow "SL001"]
let b = f = g [@@ostd.allow]
let c = (f = g) [@ostd.allow "SL002"]
