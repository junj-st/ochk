let fs = [ (fun x -> x + 1); (fun x -> x * 2) ]
let sorted = List.sort compare fs
