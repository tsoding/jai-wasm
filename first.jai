#import "Basic";
#import "Compiler";
#import "BuildCpp";
#import "Process";
#import "File";
#import "String";

build_wasm :: (base_name: string) {
    cmd :: (args: .. string, redirect_stdout_to_file := "", loc := #caller_location) {
        log("[CMD] %\n", get_quoted_command_string(args));

        result, output_string, error_string := run_command(..args, capture_and_return_output = redirect_stdout_to_file != "");
        if result.exit_code {
            if output_string then log("%", output_string);
            if error_string then log("%", error_string);
            compiler_report(tprint("Command failed with exit code '%'.\n", result.exit_code), loc);
            exit(result.exit_code);
        }

        if redirect_stdout_to_file then write_entire_file(redirect_stdout_to_file, output_string);
    }

    BC_NAME := tprint("%.bc", base_name);
    O_NAME := tprint("%.o", base_name);

    cmd("clang", "--target=wasm64", "-o", O_NAME, "-c", BC_NAME);
    cmd("wasm-ld", "-m", "wasm64", "--no-entry", "--export-all", "--allow-undefined", O_NAME, "-o", "./wasm/main64.wasm");
    cmd("./3rd_party/wasm64232", "-o", "./wasm/main32.wasm", "./wasm/main64.wasm");
}

prepare_object_file_for_build_wasm :: (w: Workspace) -> string {
    object_file_to_translate_to_wasm := "";
    while true {
        message := compiler_wait_for_message();
        if !message break;

        if message.kind == {
            case .TYPECHECKED; {
                typechecked := cast(*Message_Typechecked) message;
                for typechecked.procedure_bodies {
                    contains_asm := false;
                    for it.subexpressions {
                        if it.kind == .ASM {
                            // NOTE: #asm blocks are not translatable to WASM, we need to remove them
                            compiler_report("ASM DETECTED!!!", make_location(it), .WARNING);
                            contains_asm = true;
                        }
                    }
                    if contains_asm {
                        body := it.expression;
                        // TODO: delete only the ASM blocks
                        // I'm just too lazy to write such a surgically precise code right now, sorry
                        compiler_report(tprint("Removing the whole body of the function %. DON'T USE IT!!!", body.header.name),
                                        make_location(body),
                                        .WARNING);
                        new_statements : [..] *Code_Node;
                        body.block.statements = new_statements;
                        compiler_modify_procedure(w, body);
                    }
                }
            }

            case .PHASE; {
                phase := cast(*Message_Phase) message;
                if phase.phase == .POST_WRITE_EXECUTABLE {
                    assert(phase.compiler_generated_object_files.count == 1, "The build process supports only a single object file compilation");
                    assert(object_file_to_translate_to_wasm.count == 0, "The build process supports only a single object file compilation");
                    object_file_to_translate_to_wasm = phase.compiler_generated_object_files[0];
                }
            }

            case .COMPLETE; break;
        }
    }

    return object_file_to_translate_to_wasm;
}

#run {
    assert(OS == .LINUX, "TODO: Only Linux is supported for now");

    w := compiler_create_workspace("Jai WASM");
    if !w {
        print("Error: Could not create a workspace\n");
        exit(1);
    }

    if !build_cpp_dynamic_lib("libwasmstub", "wasmstub.c") {
        print("Error: Could not build dynamic lib with external names");
        exit(1);
    }

    bo := get_build_options(w);
    bo.output_executable_name            = "wasm-jai";
    bo.llvm_options.output_bitcode       = true;
    bo.llvm_options.enable_split_modules = false;
    set_build_options(bo, w);

    compiler_begin_intercept(w);
    add_build_file("main.jai", w);
    object_file_to_translate_to_wasm := prepare_object_file_for_build_wasm(w);
    compiler_end_intercept(w);

    if object_file_to_translate_to_wasm.count > 0 {
        build_wasm(path_strip_extension(object_file_to_translate_to_wasm));
    } else {
        print("Could not generate the object file. Skipping WASM translation step...\n");
    }

    set_build_options_dc(.{do_output=false});
}
