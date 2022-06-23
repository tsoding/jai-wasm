#import "Basic";
#import "Compiler";
#import "BuildCpp";
#import "Process";
#import "File";

THIRD_PARTY_PATH :: "./3rd_party";
LLVM_VERSION :: "13.0.0";
WABT_VERSION :: "1.0.29";

cmd :: (args: .. string, redirect_stdout_to_file := "", loc := #caller_location) {
    result, output_string, error_string := run_command(..args, capture_and_return_output = redirect_stdout_to_file != "");
    if result.exit_code {
        if output_string then log("%", output_string);
        if error_string then log("%", error_string);
        compiler_report(tprint("Command failed with exit code ''%'.\n", result.exit_code), loc);
        exit(result.exit_code);
    }

    if redirect_stdout_to_file then write_entire_file(redirect_stdout_to_file, output_string);
}

build_wasm :: (w: Workspace, target := OS) {
    assert(target == .LINUX, "TODO: Only Linux supported for now");

    bo := get_build_options(w);

    CLANG := tprint("%/clang+llvm-%-x86_64-linux-gnu-ubuntu-16.04/bin/clang", THIRD_PARTY_PATH, LLVM_VERSION);
    WASMLD := tprint("%/clang+llvm-%-x86_64-linux-gnu-ubuntu-16.04/bin/wasm-ld", THIRD_PARTY_PATH, LLVM_VERSION);
    WASM2WAT := tprint("%/wabt-%/bin/wasm2wat", THIRD_PARTY_PATH, WABT_VERSION);
    WAT2WASM := tprint("%/wabt-%/bin/wat2wasm", THIRD_PARTY_PATH, WABT_VERSION);

    // TODO: get the name of the object file somehow automatically
    // Probably via the compiler interseption
    BASE_NAME :: "wasm-jai_0_w3";
    LL_NAME := tprint("%/%.ll", bo.intermediate_path, BASE_NAME);
    O_NAME := tprint("%/%.o", bo.intermediate_path, BASE_NAME);
    WAT_NAME := tprint("%/%.wat", bo.intermediate_path, BASE_NAME);
    FIXED_O_NAME := tprint("%/%_fixed.o", bo.intermediate_path, BASE_NAME);
    FIXED_WAT_NAME := tprint("%/%_fixed.wat", bo.intermediate_path, BASE_NAME);

    cmd(CLANG, "--target=wasm32", "-o", O_NAME, "-c", LL_NAME);
    cmd(WASM2WAT, O_NAME, redirect_stdout_to_file = WAT_NAME);
    cmd(WAT2WASM, "-r", WAT_NAME, "-o", FIXED_O_NAME);
    cmd(WASM2WAT, FIXED_O_NAME, redirect_stdout_to_file = FIXED_WAT_NAME);
    cmd(WASMLD, "-m", "wasm32", "--no-entry", "--export-all", "--allow-undefined", FIXED_O_NAME, "-o", "main.wasm");
    cmd(WASM2WAT, "./main.wasm", redirect_stdout_to_file = "main.wat");
    cmd(WAT2WASM, "main.wat", "-o", "main_fixed.wasm");
}

#run {
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
    bo.stack_trace                       = false;
    bo.use_ansi_color                    = false;
    bo.array_bounds_check                = .OFF;
    bo.cast_bounds_check                 = .OFF;
    bo.math_bounds_check                 = .OFF;
    bo.null_pointer_check                = .OFF;
    bo.emit_debug_info                   = .NONE;
    bo.llvm_options.output_llvm_ir       = true;
    bo.llvm_options.enable_split_modules = false;
    set_build_options(bo, w);

    compiler_begin_intercept(w);

    add_build_file("main.jai", w);

    while true {
        message := compiler_wait_for_message();
        if !message break;

        if message.kind == {
            case .TYPECHECKED; {
                typechecked := cast(*Message_Typechecked) message;
                for typechecked.all {
                    for it.subexpressions {
                        if it.kind == .ASM {
                            // TODO: could we just delete the asm blocks so we don't have to patch anything?
                            // You end up not using code with asm blocks anyway.
                            print("%:%: ASM DETECTED!!!\n",
                                  it.location.enclosing_load.fully_pathed_filename,
                                  it.location.l0);
                        }
                    }
                }
            }

            case .COMPLETE; break;
        }
    }

    compiler_end_intercept(w);

    build_wasm(w);

    set_build_options_dc(.{do_output=false});
}
