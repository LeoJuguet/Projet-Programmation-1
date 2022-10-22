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
 movq %rdi, %rsi
 movq $S_float, %rdi
 movq $1, %rax
 call printf
 ret
" and s_float = label "S_float" ++ string "%f\n"

type code = {mutable text: text;mutable data: data}

let ast_to_asm ast name=
  let code= {
      text = globl "main" ++ label "main";
      data =nop }
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
      | Divi (x,y) -> raise NotImplemented
      | Modi (x,y) ->raise NotImplemented
      | Convfi (x) -> sexfloat_to_asm x
    and
      sexfloat_to_asm ast = match ast with
      | Float x ->raise NotImplemented
      | Addf (x,y) ->raise NotImplemented
      | Subf (x,y) -> raise NotImplemented
      | Timesf (x,y) -> raise NotImplemented
      | Convif (x) -> raise NotImplemented
  in (match ast with
     | Intexp a ->begin
         sexint_to_asm a;
         code.text <- code.text
                      ++ popq rdi
                      ++ call "print_int"
                      ++ xorq (reg rax) (reg rax)
                      ++ ret
                      ++ inline print_int;
         code.data <- code.data
                      ++ label "S_int"
                      ++ string "%d\n";
         end
     | Floatexp a -> sexfloat_to_asm a;
                     print_string "execcc");
    let codef:program = {text = code.text; data = code.data} in
    print_in_file ~file:name codef;

