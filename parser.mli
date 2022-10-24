type token =
  | INT of (string)
  | FLOAT of (string)
  | NAME of (string)
  | LBRACE
  | RBRACE
  | EOF
  | ADD
  | SUB
  | TIMES
  | DIV
  | MOD
  | FACT
  | EXP
  | ADDDOT
  | SUBDOT
  | TIMESDOT
  | DIVDOT
  | DOT
  | INTOFFLOAT
  | FLOATOFINT

val parse :
  (Lexing.lexbuf  -> token) -> Lexing.lexbuf -> Asyntax.sexp
