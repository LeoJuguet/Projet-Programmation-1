
%token <string> INT
%token <string> FLOAT
%token <string> NAME

%token LBRACE RBRACE EOF ADD SUB TIMES DIV MOD FACT EXP ADDDOT SUBDOT TIMESDOT DIVDOT DOT INTOFFLOAT FLOATOFINT EQUAL EOL


%left ADD SUB ADDDOT SUBDOT
%left TIMES DIV FACT TIMESDOT DIVDOT
%left MOD
%nonassoc EQUAL
%nonassoc EOL
%nonassoc EOF
%start parse

%type <Asyntax.sexp> parse
%%

parse:
  | NAME EQUAL sexint EOL parse  {Asyntax.Sequence (Asyntax.Assigni($1,$3), $5)}
  | NAME EQUAL sexfloat EOL parse {Asyntax.Sequence (Asyntax.Assignf($1,$3), $5)}
  | sexp EOL {$1}
  | sexp EOF {$1}
  | EOF {Asyntax.SequenceEND}
;

sexp:
  |sexint             {Asyntax.Intexp $1}
  |sexfloat           {Asyntax.Floatexp $1}
  | NAME              {Asyntax.VariableU $1}
;
sexint:
  |sexint ADD sexint {Asyntax.Addi($1,$3)}
  |sexint SUB sexint {Asyntax.Subi($1,$3)}
  |sexint TIMES sexint {Asyntax.Timesi($1,$3)}
  |sexint DIV sexint {Asyntax.Divi($1,$3)}
  |sexint MOD sexint {Asyntax.Modi($1,$3)}
  |ADD LBRACE sexint RBRACE {Asyntax.UAddi $3}
  |SUB LBRACE sexint RBRACE {Asyntax.USubi $3}
  |INTOFFLOAT LBRACE sexfloat RBRACE {Asyntax.Convfi $3}
  |LBRACE sexint RBRACE {$2}
  |sexint FACT {Asyntax.Fact $1}
  |sexint EXP sexint {Asyntax.Expi ($1,$3)}
  |NAME {Asyntax.Variablei $1}
  |INT {Asyntax.Int $1}
;
sexfloat:
  |sexfloat ADDDOT sexfloat {Asyntax.Addf($1,$3)}
  |sexfloat SUBDOT sexfloat {Asyntax.Subf($1,$3)}
  |sexfloat TIMESDOT sexfloat {Asyntax.Timesf($1,$3)}
  |ADD LBRACE sexfloat RBRACE {Asyntax.UAddf $3}
  |SUB LBRACE sexfloat RBRACE {Asyntax.USubf $3}
  |FLOATOFINT LBRACE sexint RBRACE {Asyntax.Convif $3}
  |LBRACE sexfloat RBRACE {$2}
  |sexfloat EXP sexint {Asyntax.Expf($1,$3)}
  |NAME {Asyntax.Variablef $1}
  |FLOAT {Asyntax.Float $1}
;
