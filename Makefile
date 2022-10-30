NAME=aritha
MAIN_OBJS=asyntax.cmo parser.cmo lexer.cmo x86_64.cmo assembler.cmo main.cmo

RED=\033[0;31m
GREEN=\033[0;32m
NOCOLOR=\033[0m

all: $(NAME) rapport.pdf

$(NAME): .depend $(MAIN_OBJS)
	ocamlc -o $(NAME) $(MAIN_OBJS)

rapport.pdf: rapport/rapport.tex
	pdflatex -shell-escape rapport/rapport.tex -o rapport.pdf

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

parser.cmo: parser.cmi
parser.mli : parser.mly
parser.ml : parser.mly


#Test
TEST=test
TESTEXP=$(wildcard $(TEST)/*.exp)
TESTS=$(TESTEXP:.exp=)
count=

test: cleantest $(TESTS)
	@echo Test passed : $$(wc -l compteur.sup | tr -dc '0-9')/$(words $(TESTEXP))
	@rm compteur.sup

test/%.s: $(NAME) test/%.exp
	@./$(NAME) $(basename $@).exp -o $@

test/%: test/%.s
	@gcc -no-pie $@.s -o $@;\
	./$(basename $@) >  $(basename $@).tmp 2>/dev/null; \
	echo $(basename $@): ;\
		./$(basename $@) > $(basename $@).tmp 2>/dev/null; \
		if diff $(basename $@).ok $(basename $@).tmp; \
			then (echo "\t$(GREEN)Success $(NOCOLOR)"; echo "1" >> compteur.sup) \
		else echo "\t$(RED)Failed $(NOCOLOR)"; \
		fi; \

test/%.ok: test/% test/%.s
	@gcc -no-pie $(basename $@).s -o $(basename $@); \
	./$(basename $@) >  $(basename $@).ok 2>/dev/null;

update_test: $(TESTS)
	@for i in $(TESTS) ; do \
	cp $$i.tmp $$i.ok;\
	done;\
	echo test updated;\

listTest: $(TESTSEXP)
	@echo $(TESTS) | awk -v OFS="\n" '$$1=$$1'

#Clean
clean:	cleantest
	@rm -rf aritha *~ *.cm[iox] *.o parser.ml parser.mli lexer.ml *.tmp *.s
	@rm -rf *.aux *.log *.out *.pdf
	@echo cleaned project

cleantest:
	@rm -f $(TESTS) $(TESTS:=.tmp) $(TESTS:=.s)
	@echo cleaned test



.depend:
	ocamldep *.mli *.ml *.mly *.mll > .depend

include .depend
