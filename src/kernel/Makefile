##
# Make-A-System
#
# @file
# @version 0.1

all: system
	objcopy -I elf64-x86-64 -S -R ".eh_frame" -R ".comment" -O binary system kernel.bin

system: head.o main.o printk.o
	ld -b elf64-x86-64 -z muldefs -o system head.o main.o printk.o -T Kernel.lds

head.o: head.S
	gcc -E  head.S > head.s
	as --64 -o head.o head.s

main.o: main.c
	gcc  -mcmodel=large -fno-builtin -m64 -c main.c

printk.o: printk.c
	gcc  -mcmodel=large -fno-builtin -fno-stack-protector -m64 -c printk.c

clean:
	rm -rf *.o *.s~ *.s *.S~ *.c~ *.h~ system  Makefile~ Kernel.lds~ kernel.bin

# end
