{
        open Parser
        exception Eof
}

rule token = parse
  [' ' '\t'] {token lexbuf}
| '\n'  {EOL}
| '('   {LBRACE}
| ')'   {RBRACE}
| '+'   {ADD}
| '-'   {SUB}
| '*'   {TIMES}
| '/'   {DIV}
| '%'   {MOD}
| '!'   {FACT}
| "**"  {EXP}
| "^"   {EXP}
| "+."  {ADDDOT}
| "-."  {SUBDOT}
| "*."  {TIMESDOT}
| "/."  {DIVDOT}
| "="   {EQUAL}
| ('-'|'+')?['0'-'9']+'.'['0'-'9']*  {FLOAT(Lexing.lexeme lexbuf)}
| '.'['0'-'9']+ {FLOAT(Lexing.lexeme lexbuf)}
| ('-'|'+')?['0'-'9']+    {INT(Lexing.lexeme lexbuf)}
| "int"         {INTOFFLOAT}
| "float"       {FLOATOFINT}
| ['A'-'Z' 'a'-'z' '_']['A'-'Z' 'a'-'z' '0'-'9' '_']*  {NAME(Lexing.lexeme lexbuf)}
| eof {EOF}
