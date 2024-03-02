# How to set up debugging with gdb
Clion create new RunConfig:
    Remote Debugging->choose debugger as gdb
        ->target remote args as "localhost:1234"
        ->choose before launch --> add make debug_bootloader