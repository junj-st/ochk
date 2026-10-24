let x = Float.of_string "nan"
let bad1 = x = nan
let bad2 = x <> Float.nan
let bad3 = nan < x
let fine1 = Float.is_nan x
let fine2 = Float.equal x nan
let fine3 = compare x nan = 0
let fine4 = x = 1.0
let allowed = (x = nan) [@ochk.allow "SL005"]
