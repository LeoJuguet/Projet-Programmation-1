open Asyntax
open Format
open X86_64

exception NotImplemented
exception AsmError of string

(*Some function callable in program*)

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

(*type with the same form of X86_64 but with mutable arguments*)
type code = {mutable text: text;mutable data: data}

(*Type for typechecking of variable*)
type variable_type = Int | Float | Unknow


let ast_to_asm ast name=
  let code= {
      text = globl "main"
             ++ label "main"
             ++ pushq (reg rbp)
             ++ movq (reg rsp) (reg rbp);
      data = nop }
  in
  (*with save the type and all variable declare for find the position in list*)
  let variable = ref [] in

  (*Some variable for know if we have to add some function or data in asm*)
  let addfact = ref false in
  let addexpint = ref false in
  let addexpfloat = ref false in

  (*Counter for declare float in data*)
  let nbfloat = ref 0 in

  (*Function for integrate variable*)
  let variable_exist x =
    let rec aux l i= match l with
        | [] -> Unknow, i
        | (a,t)::q when a = x -> t,i
        | t::q -> aux q (i+1)
    in aux !variable 0
  in
  let set_variable x t =
    let rec aux l= match l with
        | [] -> raise (AsmError "Unknow error")
        | (a,ta)::q when a = x -> (a,t)::q
        | t::q -> t::aux q
    in variable := aux !variable
  in

  (*Instruction for push float on stack*)
  let pushfnew regf = subq (imm 8) (reg rsp)
                      ++ inline ("\tmovsd "^regf^",%xmm0\n")
                      ++ inline ("\tmovsd %xmm0, (%rsp)\n")
  in

  (*Instruction for push float on stack*)
  let pushf regf= subq (imm 8) (reg rsp)
                  ++ inline ("\tmovsd "^regf^",(%rsp)\n")
  in

  (*Instruction for pop float on stack*)
  let popf regf= inline ("\tmovsd (%rsp),"^regf^"\n")
              ++ addq (imm 8) (reg rsp)
  in

  (*Code for int opperation*)
  let rec opp_i x y op=
    sexint_to_asm x;
    sexint_to_asm y;
    code.text <- code.text
                 ++ popq rdi
                 ++ popq rsi
                 ++ op (reg rdi) (reg rsi)
                 ++ pushq (reg rsi);

    and
      (*Transform expression of type int in asm*)
      sexint_to_asm (ast:sexpint) = match ast with
      | Int x -> begin
          code.text <- code.text
                       ++ pushq (imm (int_of_string x));
        end
      | Variablei x -> begin
          let t,pos = variable_exist x in
          match t with
            | Unknow -> raise (AsmError ("Variable "^x^" is unknow"))
            | Float -> raise (AsmError ("Variable "^x^" is a float but a int is attempt"))
            | Int -> begin
                code.text <- code.text
                             ++ inline ("\tmovq "^string_of_int((-pos-1)*8)^"(%rbp), %rax\n")
                             ++ pushq (reg rax);
              end
        end
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
                       ++ pushq (reg rax);
        end
      | Modi (x,y) -> begin
          sexint_to_asm x;
          sexint_to_asm y;
          code.text <- code.text
                       ++ popq rcx
                       ++ popq rax
                       ++ xorq (reg rdx) (reg rdx)
                       ++ idivq (reg rcx)
                       ++ pushq (reg rdx);
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
                       ++ inline "cvttsd2siq %xmm0, %rax\n"
                       ++ pushq (reg rax);
        end
    and
      (*Transform float expression to asm*)
      sexfloat_to_asm ast = match ast with
      | Float x -> begin
          code.data <- code.data
                       ++ label (".F"^string_of_int !nbfloat)
                       ++ inline ("\t.double "^x^"\n");
          code.text <- code.text
                       ++ pushfnew (".F"^string_of_int !nbfloat);
          incr nbfloat;
          end
      | Variablef x -> begin
          let t,pos = variable_exist x in
          match t with
            | Unknow -> raise (AsmError ("Variable "^x^" is unknow"))
            | Int -> raise (AsmError ("Variable "^x^" is a int but a float is attempt"))
            | Float -> begin
                code.text <- code.text
                             ++ inline ("\tmovsd "^string_of_int((-pos-1)*8)^"(%rbp), %xmm0\n")
                             ++ pushf "%xmm0";
              end
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
                       ++ inline "\tcvtsi2sdq %rax, %xmm0\n"
                       ++ pushf "%xmm0";
        end
  and
    (*Transform general expression to asm*)
    sexp_to_asm ast = match ast with
    | Assigni (x,a) -> begin
        let t,pos = variable_exist x in
        match t with
        | Unknow -> begin
            sexint_to_asm a;
            variable := !variable@[(x,Int)];
        end
        | _ -> begin
            sexint_to_asm a;
            code.text <- code.text
                         ++ popq rax
                         ++ inline ("\tmovq %rax, "
              ^string_of_int((-pos-1)*8)^"(%rbp)\n");
            set_variable x Int;
            end
      end
    | Assignf (x,a) -> begin
        let t,pos = variable_exist x in
        match t with
        | Unknow -> begin
            sexfloat_to_asm a;
            variable := !variable@[(x,Float)];
        end
        | _ -> begin
            sexfloat_to_asm a;
            code.text <- code.text
                         ++ popf "%xmm0"
                         ++ inline ("\tmovsd %xmm0, "^string_of_int((-pos-1)*8)^"(%rbp)\n");
            set_variable x Float;
            end
      end
    | VariableU x-> begin
        let t,pos = variable_exist x in
        match t with
        | Unknow -> raise (AsmError ("Variable "^x^" is unknown"))
        | Int -> sexp_to_asm (Intexp (Variablei x))
        | Float -> sexp_to_asm (Floatexp (Variablef x))
      end
    | Intexp a ->begin
         sexint_to_asm a;
         code.text <- code.text
                      ++ popq rdi
                      ++ addq (imm ((List.length !variable)*8))
                           (reg rsp) (*clear variable*)
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
                      ++ addq (imm ((List.length !variable)*8)) (reg rsp) (*clear variable*)
                      ++ popq rbp
                      ++ call "print_float"
                      ++ xorq (reg rax) (reg rax)
                      ++ ret
                      ++ inline print_float;
         code.data <- code.data
                      ++ label "S_float"
                      ++ string "%f\n";
       end
    | Sequence (x,y) -> begin
        sexp_to_asm x;
        sexp_to_asm y;
      end
    | SequenceEND -> ()

  in sexp_to_asm ast;

     (*Incorporate function use in asm*)
     if !addfact then code.text <- code.text ++ inline fact;
     if !addexpint then code.text <- code.text ++ inline expint;
     if !addexpfloat then
       (code.text <- code.text ++ inline expfloat;
        code.data <- code.data ++ inline dataexpfloat;);

    let codef:program = {text = code.text; data = code.data} in
    print_in_file ~file:name codef;
