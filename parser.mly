
%token <string> INT
%token <string> FLOAT
%token <string> NAME

%token LBRACE RBRACE EOF DOT ADD SUB TIMES DIV MOD

%left ADD SUB
%left TIMES DIV
%left MOD DOT
%start parse

%type <Asyntax.sexp> parse
%%

parse:
 sexp { $1 }
;

sexp:
  |sexint {Asyntax.Intexp $1}
  |sexfloat {Asyntax.Floatexp $1}
;
sexint:
  |sexint ADD sexint {Asyntax.Addi($1,$3)}
  |sexint SUB sexint {Asyntax.Subi($1,$3)}
  |sexint TIMES sexint {Asyntax.Timesi($1,$3)}
  |sexint DIV sexint {Asyntax.Divi($1,$3)}
  |sexint MOD sexint {Asyntax.Modi($1,$3)}
  |LBRACE sexint RBRACE {$2}
  |INT {Asyntax.Int $1}
;
sexfloat:
  |sexfloat ADD DOT sexfloat {Asyntax.Addf($1,$4)}
  |sexfloat SUB DOT sexfloat {Asyntax.Subf($1,$4)}
  |sexfloat TIMES DOT sexfloat {Asyntax.Timesf($1,$4)}
  |LBRACE sexfloat RBRACE {$2}
  |FLOAT {Asyntax.Float $1}
;
