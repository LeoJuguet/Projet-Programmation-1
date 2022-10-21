all: aritha

aritha: aritha.ml
	ocamlc aritha.ml -o aritha
lexer:
	ocamllex lexer.mll
parser:
	ocamlyacc parser.mly
