exception Error of string

type sexp =
  Intexp of sexpint
| Floatexp of sexfloat
and
 sexpint =
  Int of string
 |Addi of sexpint * sexpint
 |Subi of sexpint * sexpint
 |Timesi of sexpint *sexpint
 |Divi of sexpint * sexpint
 |Modi of sexpint * sexpint
 |Convfi of sexfloat
and sexfloat =
  Float of string
|Addf of sexfloat * sexfloat
|Subf of sexfloat * sexfloat
|Timesf of sexfloat * sexfloat
|Convif of sexpint
