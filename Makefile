all: aritha

MAIN_OBJS=asyntax.cmo parser.cmo lexer.cmo x86_64.cmo assembler.cmo main.cmo

aritha: .depend $(MAIN_OBJS)
	ocamlc -o aritha $(MAIN_OBJS)



.SUFFIXES: .ml .mli .cmo .cmi .cmx .mll .mly

.mll.ml:
	ocamllex $<
.mly.ml:
	ocamlyacc $<
.ml.cmo:
	ocamlc -c $<
.mli.cmi:
	ocamlc -c $<
.ml.cmx:
	ocamlc -c $<

clean:
	rm -f aritha *~ *.cm[iox] *.o parser.ml parser.mli lexer.ml

parser.cmo: parser.cmi
parser.mli : parser.mly
parser.ml : parser.mly

.depend:
	ocamldep *.mli *.ml *.mly *.mll > .depend

include .depend
