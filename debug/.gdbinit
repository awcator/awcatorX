cd ~/awcatorX/bin/
#break *0x7C00
define rg16
  info registers ax ah al bx bh bl cx ch cl dx dh cl si di bp sp ds es ss cs sp
end
break print_string_pointed_by_ds_and_si
set architecture i8086
file ./awcator_bootloader.elf
