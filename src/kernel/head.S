// 所谓内核执行头程序，其实是内核程序中的一小段汇编代码。
// 当Loader引导加载程序移交控制权后，处理器便会执行Kernel内核程序的这段代码。
// 内核执行头程序负责为操作系统创建段结构和页表结构、设置某些结构的默认处理函数、配置关键寄存器等工作。
// 在完成上述工作后，依然要借助远跳转指令才能进入系统内核主程序。

//|          |
//|  Kernel  |
//|__________|
//|  head.S  |
//|__________| 1MB
//|          |
//|BootLoader|
//|__________|0

.section .text

.global _start

_start:

  mov $0x10,  %ax
  mov %ax,  %ds
  mov %ax,  %es
  mov %ax,  %fs
  mov %ax,  %ss
  mov $0x7E00,  %esp

//======= load GDTR

  lgdt  GDT_POINTER(%rip)

//======= load  IDTR

  lidt  IDT_POINTER(%rip)

  mov $0x10,  %ax
  mov %ax,  %ds
  mov %ax,  %es
  mov %ax,  %fs
  mov %ax,  %gs
  mov %ax,  %ss

  movq  $0x7E00,  %rsp

//======= load  cr3

  movq  $0x101000,  %rax
  movq  %rax,   %cr3
  movq  switch_seg(%rip), %rax
  pushq $0x08
  pushq %rax
  lretq

//======= 64-bit mode code

switch_seg:
  .quad entry64

entry64:
  movq  $0x10,  %rax
  movq  %rax, %ds
  movq  %rax, %es
  movq  %rax, %gs
  movq  %rax, %ss
  movq  $0xffff800000007E00,  %rsp    /* rsp address */

  movq  go_to_kernel(%rip), %rax    /* movq address */
  pushq $0x08
  pushq %rax
  lretq

go_to_kernel:
  .quad Start_Kernel


// ======= init page
// 在64位的IA-32e模式下，页表最高可分为4个等级, 每个页表项由原来的4 B扩展至8 B，
// 而且分页机制除了提供4 KB大小的物理页外，还提供2 MB和1 GB大小的物理页
.align 8 // 伪指令．align将对齐标准设置为8B

.org 0x1000 // 伪指令．org来固定各个页表的起始地址
// 以页目录（顶层页表）为例，使用代码．org 0x1000定位页目录后
// 此页表便位于内核执行头程序起始地址0x1000偏移处
// 然后链接器再根据链接脚本的描述，将内核执行头程序的起始线性地址
// 设置在0xffff800000000000 + 0x100000地址处
// 因此推算出页目录的起始线性地址
// 位于0xffff 800000100000+ 0x1000 = 0xffff800000101000处
//
// 此页表将线性地址0和0xffff800000000000映射为同一物理页以方便页表切换，
// 即程序在配置页表前运行于线性地址0x100000附近，
// 经过跳转后运行于线性地址0xffff800000000000附近。
__PML4E:

  .quad 0x102007
  .fill 255,8,0
  .quad 0x102007
  .fill 255,8,0

.org 0x2000

__PDPTE:

  .quad 0x103003
  .fill 511,8,0

.org 0x3000

__PDE:

  .quad 0x000083
  .quad 0x200083
  .quad 0x400083
  .quad 0x600083
  .quad 0x800083
  .quad 0xe0000083    /*0x a00000*/
  .quad 0xe0200083
  .quad 0xe0400083
  .quad 0xe0600083    /*0x1000000*/
  .quad 0xe0800083
  .quad 0xe0a00083
  .quad 0xe0c00083
  .quad 0xe0e00083
  .fill 499,8,0 // 将数值0填充到页表的剩余499个页表项里

//======= GDT_Table

.section .data

.globl GDT_Table // 全局描述符表
  // 伪指令．globl的作用相当于C语言的extern关键字，
  // 它可以保证在本程序正常配置描述符表项的同时，
  // 内核程序的其他部分也能够操作这些描述符表项
  //
  // 向IDT表项设置中断/异常处理函数、
  // 保存/还原各个进程的任务状态段信息、
  // 创建LDT描述符表（本系统不使用LDT表功能）等

GDT_Table:
  .quad 0x0000000000000000      /*0 NULL descriptor           00*/
  .quad 0x0020980000000000      /*1 KERNEL  Code  64-bit  Segment 08*/
  .quad 0x0000920000000000      /*2 KERNEL  Data  64-bit  Segment 10*/
  .quad 0x0020f80000000000      /*3 USER  Code  64-bit  Segment 18*/
  .quad 0x0000f20000000000      /*4 USER  Data  64-bit  Segment 20*/
  .quad 0x00cf9a000000ffff      /*5 KERNEL  Code  32-bit  Segment 28*/
  .quad 0x00cf92000000ffff      /*6 KERNEL  Data  32-bit  Segment 30*/
  .fill 10,8,0          /*8 ~ 9 TSS (jmp one segment <7>) in long-mode 128-bit 40*/
GDT_END:

GDT_POINTER:
GDT_LIMIT:  .word GDT_END - GDT_Table - 1
GDT_BASE: .quad GDT_Table

//======= IDT_Table

.globl IDT_Table // 中断描述符表

IDT_Table:
  .fill  512,8,0
IDT_END:

IDT_POINTER:
IDT_LIMIT:  .word IDT_END - IDT_Table - 1
IDT_BASE: .quad IDT_Table

//======= TSS64_Table

.globl  TSS64_Table // 任务状态段

TSS64_Table:
  .fill  13,8,0
TSS64_END:

TSS64_POINTER:
TSS64_LIMIT:  .word TSS64_END - TSS64_Table - 1
TSS64_BASE: .quad TSS64_Table
