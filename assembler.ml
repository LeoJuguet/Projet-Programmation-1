open Asyntax
open Format
open X86_64

exception NotImplemented

let print_int =
"print_int:
\tmovq %rdi, %rsi
\tmovq $S_int, %rdi
\txorq %rax, %rax
\tcall printf
\tret
 " and s_int = label "S_int"++ string "%d\n"

let print_float =
"print_float:
\tmovq $S_float, %rdi
\tmovq $1, %rax
\tcall printf
\tret\n"
 and s_float = label "S_float" ++ string "%f\n"

let fact =
".fact:
\tmovq %rdi, %rbx
\tmovq $1, %rax
\tcmpq $0,%rdi
\tjnz .loopfact
\tret
.loopfact:
\timulq %rbx, %rax
\tdecq %rbx
\tjnz .loopfact
\tret\n"

let expint =
"
.expint:
\tmovq $1, %rax
\tcmpq $0, %rdi
\tjnz .loopexpint
\tret
.loopexpint:
\timulq %rdi, %rax
\tdecq %rsi
\tjnz .loopexpint
\tret\n
"
let expfloat =
"
.expfloat:
\tmovsd %xmm0, %xmm1
\tmovsd .CST1, %xmm0
\tcmpq $0, %rdi
\tjnz .loopexpfloat
\tret
.loopexpfloat:
\tmulsd %xmm1, %xmm0
\tdecq %rdi
\tjnz .loopexpfloat
\tret\n
" and
dataexpfloat = ".CST1:\n\t.double 1.0\n"

type code = {mutable text: text;mutable data: data}

let ast_to_asm ast name=
  let code= {
      text = globl "main" ++ label "main" ++ pushq (reg rbp);
      data =nop }
  in
  let addfact = ref false in
  let addexpint = ref false in
  let addexpfloat = ref false in
  let nbfloat = ref 0 in
  let pushfnew regf = subq (imm 8) (reg rsp)
                      ++ movq (reg rsp) (reg rbp)
                      ++ inline ("\tmovsd "^regf^",%xmm0\n")
                      ++ inline ("\tmovsd %xmm0, 8(%rsp)\n")
  in
  let pushf regf= subq (imm 8) (reg rsp)
                  ++ inline ("\tmovsd "^regf^",8(%rsp)\n")
  in
  let popf regf= inline ("\tmovsd 8(%rsp),"^regf^"\n")
              ++ addq (imm 8) (reg rsp)
  in
  let rec opp_i x y op=
    sexint_to_asm x;
    sexint_to_asm y;
    code.text <- code.text ++ popq rax ++ popq rbx ++ op (reg rax) (reg rbx) ++ pushq (reg rbx)

    and
      sexint_to_asm ast = match ast with
      | Int x -> code.text <- code.text ++ pushq (imm (int_of_string x))
      | Addi (x,y) -> opp_i x y addq
      | Subi (x,y) -> opp_i x y subq
      | Timesi (x,y) -> opp_i x y imulq
      | Divi (x,y) -> begin
          sexint_to_asm x;
          sexint_to_asm y;
          code.text <- code.text
                       ++ popq rcx
                       ++ popq rax
                       ++ xorq (reg rdx) (reg rdx)
                       ++ idivq (reg rcx)
                       ++ pushq (reg rax)
        end
      | Modi (x,y) -> begin
          sexint_to_asm x;
          sexint_to_asm y;
          code.text <- code.text
                       ++ popq rcx
                       ++ popq rax
                       ++ xorq (reg rdx) (reg rdx)
                       ++ idivq (reg rcx)
                       ++ pushq (reg rdx)
        end
      |Fact x -> begin
          sexint_to_asm x;
          code.text <- code.text
                       ++popq rdi
                       ++call ".fact"
                       ++pushq (reg rax);
          addfact := true;
        end
      |UAddi x -> sexint_to_asm x
      |USubi x ->begin
          sexint_to_asm x;
          code.text <- code.text
                       ++ popq rax
                       ++ negq (reg rax)
                       ++ pushq (reg rax);
        end
      |Expi(x,y) -> begin
        sexint_to_asm x;
        sexint_to_asm y;
        code.text <- code.text
                     ++ popq rsi
                     ++ popq rdi
                     ++ call ".expint"
                     ++ pushq (reg rax);
        addexpint := true;
        end
      | Convfi (x) -> begin
          sexfloat_to_asm x;
          code.text <- code.text
                       ++ popf "%xmm0"
                       ++ inline "cvttsd2siq\t%xmm0, %rax\n"
                       ++ pushq (reg rax);
        end
    and
      sexfloat_to_asm ast = match ast with
      | Float x -> begin
          code.data <- code.data
                       ++ label (".F"^string_of_int !nbfloat)
                       ++ inline ("\t.double "^x^"\n");
          code.text <- code.text
                       ++ pushfnew (".F"^string_of_int !nbfloat);
          incr nbfloat;
          end
      | Addf (x,y) -> begin
          sexfloat_to_asm y;
          sexfloat_to_asm x;
          code.text <- code.text
                       ++ popf "%xmm0"
                       ++ popf "%xmm1"
                       ++ inline ("\taddsd %xmm0, %xmm1\n")
                       ++ pushf "%xmm1";
          end
      | Subf (x,y) -> begin
          sexfloat_to_asm x;
          sexfloat_to_asm y;
          code.text <- code.text
                       ++ popf "%xmm1"
                       ++ popf "%xmm0"
                       ++ inline ("\tsubsd %xmm1, %xmm0\n")
                       ++ pushf "%xmm0";
          end
      | Timesf (x,y) -> begin
          sexfloat_to_asm x;
          sexfloat_to_asm y;
          code.text <- code.text
                       ++ popf "%xmm1"
                       ++ popf "%xmm0"
                       ++ inline ("\tmulsd %xmm1, %xmm0\n")
                       ++ pushf "%xmm0";
          end
      |UAddf x -> sexfloat_to_asm x; (* +x = x*)
      |USubf x -> sexfloat_to_asm (Subf(Float("0.0"),x)) (* -x = 0 - x*)
      |Expf (x,y) -> begin
          sexfloat_to_asm x;
          sexint_to_asm y;
          code.text <- code.text
                       ++ popq rdi
                       ++ popf "%xmm0"
                       ++ call ".expfloat"
                       ++ pushf "%xmm0";
          addexpfloat := true;
        end
      | Convif (x) -> begin
          sexint_to_asm x;
          code.text <- code.text
                       ++ popq rax
                       ++ inline "\tcvtsi2sdq\t%rax, %xmm0\n"
                       ++ pushf "%xmm0";
        end
  in (match ast with
     | Intexp a ->begin
         sexint_to_asm a;
         code.text <- code.text
                      ++ popq rdi
                      ++ popq rbp
                      ++ call "print_int"
                      ++ xorq (reg rax) (reg rax)
                      ++ ret
                      ++ inline print_int;
         if !addfact then code.text <- code.text ++ inline fact;
         code.data <- code.data
                      ++ label "S_int"
                      ++ string "%d\n";
         end
     | Floatexp a -> begin
         sexfloat_to_asm a;
         code.text <- code.text
                      ++ popf "%xmm0"
                      ++ popq rbp
                      ++ call "print_float"
                      ++ xorq (reg rax) (reg rax)
                      ++ ret
                      ++ inline print_float;
         if !addfact then code.text <- code.text ++ inline fact;
         code.data <- code.data
                      ++ label "S_float"
                      ++ string "%f\n";
       end);
     if !addexpint then code.text <- code.text ++ inline expint;
     if !addexpfloat then
       (code.text <- code.text ++ inline expfloat;
        code.data <- code.data ++ inline dataexpfloat;);
    let codef:program = {text = code.text; data = code.data} in
    print_in_file ~file:name codef;
