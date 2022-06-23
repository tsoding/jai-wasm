// This function is refered by main.jai. The signature here does not matter.
// What matters is the symbol name in the generated libwasmstub.so dynamic library.
//
// The idea is to trick the Jai compiler into treating this as an external function,
// so it can be substituded in load.js.
void bar(void)
{
}

// TODO: generate this file automatically?
