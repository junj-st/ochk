include Stdlib.Set

module type S = sig
  include Stdlib.Set.S

  val union_all : t list -> t
end

module Make (Ord : OrderedType) = struct
  include Stdlib.Set.Make (Ord)

  let union_all sets = Stdlib.List.fold_left union empty sets
end
