let f x = x + 1
let g x = x * 2
let a = (f = g) [@ochk.allow "SL001"]
let b = f = g [@@ochk.allow]
let c = (f = g) [@ochk.allow "SL002"]
