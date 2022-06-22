#import "Basic";
#import "Compiler";
#import "BuildCpp";

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

    set_build_options_dc(.{do_output=false});
}
