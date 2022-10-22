{
        open Parser
        exception Eof
}

rule token = parse
     [' ' '\t' '\n'] {token lexbuf}
| '('   {LBRACE}
| ')'   {RBRACE}
| '+'   {ADD}
| '-'   {SUB}
| '*'   {TIMES}
| '/'   {DIV}
| '%'   {MOD}
| '.'   {DOT}
| ['0'-'9']+'.'['0'-'9']+  {FLOAT(Lexing.lexeme lexbuf)}
| ['0'-'9']+    {INT(Lexing.lexeme lexbuf)}
| ['A'-'z' '0'-'9']+  {NAME(Lexing.lexeme lexbuf)}
| eof {EOF}
