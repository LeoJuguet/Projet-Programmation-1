exception Error of string

type sexp =
  Intexp of sexpint
| Floatexp of sexfloat
| Assigni of string * sexpint
| Assignf of string * sexfloat
| VariableU of string
| Sequence of sexp * sexp
| SequenceEND
and
sexpint =
  Int of string
|Variablei of string
|Addi of sexpint * sexpint
|Subi of sexpint * sexpint
|Timesi of sexpint *sexpint
|Divi of sexpint * sexpint
|Modi of sexpint * sexpint
|UAddi of sexpint
|USubi of sexpint
|Fact of sexpint
|Expi of sexpint * sexpint
|Convfi of sexfloat
and sexfloat =
  Float of string
|Variablef of string
|Addf of sexfloat * sexfloat
|Subf of sexfloat * sexfloat
|Timesf of sexfloat * sexfloat
|UAddf of sexfloat
|USubf of sexfloat
|Expf of sexfloat * sexpint
|Convif of sexpint
