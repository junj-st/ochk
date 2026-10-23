type tree = Leaf | Node of tree * int * tree
type 'a ptree = PLeaf | PNode of 'a ptree * 'a * 'a ptree

type even = Zero | E of odd
and odd = O of even

let t = Node (Leaf, 1, Leaf)
let a = t = Leaf
let b = PNode (PLeaf, "x", PLeaf) = PLeaf
let c = E (O Zero) = Zero
