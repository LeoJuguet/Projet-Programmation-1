open Asyntax
open Format
open X86_64

exception NotImplemented

let print_int =
"print_int:
 movq %rdi, %rsi
 movq $S_int, %rdi
 xorq %rax, %rax
 call printf
 ret
 " and s_int = label "S_int"++ string "%d\n"

let print_float =
"print_float:
        movq $S_float, %rdi
        movq $1, %rax
        call printf
        ret
" and s_float = label "S_float" ++ string "%f\n"

type code = {mutable text: text;mutable data: data}

let ast_to_asm ast name=
  let code= {
      text = globl "main" ++ label "main" ++ pushq (reg rbp);
      data =nop }
  in
  let nbfloat = ref 0 in
  let fr = ref (-1) in
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
      |UAddi x -> sexint_to_asm x
      |USubi x ->begin
          sexint_to_asm x;
          code.text <- code.text
                       ++ popq rax
                       ++ negq (reg rax)
                       ++ pushq (reg rax);
        end
      | Convfi (x) -> begin
          sexfloat_to_asm x;
          code.text <- code.text
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
                       ++ popf "%xmm0"
                       ++ popf "%xmm1"
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
      | Convif (x) -> begin
          sexint_to_asm x;
          incr fr;
          code.text <- code.text
                       ++ popq rax
                       ++ inline ("\tcvtsi2sdq\t%rax, %xmm"^string_of_int !fr^"\n");
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
         code.data <- code.data
                      ++ label "S_float"
                      ++ string "%f\n";
       end);
    let codef:program = {text = code.text; data = code.data} in
    print_in_file ~file:name codef;
