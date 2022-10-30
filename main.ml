open Asyntax
open Assembler


let usage_msg = "aritha <file> [-o <output>]"
let input_files = ref []
let output_file = ref ""
let anon_fun filename = input_files := filename :: !input_files
let speclist =
  [
    ("-o", Arg.Set_string output_file, "Set output file name");
  ]

let _ =
  Arg.parse speclist anon_fun usage_msg;
  if List.length !input_files > 1 then failwith "Compilation for some files is not implemented";
  if List.length !input_files = 0 then failwith "A file name is expected";
  let ic = open_in (List.hd !input_files) in
    let lexbuf = Lexing.from_channel ic in
    let read () = Parser.parse Lexer.token lexbuf in
    let ast = read() in
    let output_name = if !output_file = "" then Filename.remove_extension (List.hd !input_files)^".s" else !output_file
    in
    Assembler.ast_to_asm ast output_name;
