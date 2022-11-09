org 10000h
  jmp Label_Start

%include "fat12.inc"

BaseOfKernelFile  equ 0x00
OffsetOfKernelFile  equ 0x100000

BaseTmpOfKernelAddr equ 0x00
OffsetTmpOfKernelFile equ 0x7E00

MemoryStructBufferAddr  equ 0x7E00

  ;; 为向保护模式切换而准备的系统数据结构
[SECTION gdt]
  ;; 本段程序创建了一个临时GDT表
  ;; 为了避免保护模式段结构的复杂性，
  ;; 此处将代码段和数据段的段基地址都设置在0x00000000地址处，
  ;; 段限长为0xffffffff，即段可以索引0～4 GB内存地址空间
LABEL_GDT:    dd  0,0
LABEL_DESC_CODE32:  dd  0x0000FFFF,0x00CF9A00
LABEL_DESC_DATA32:  dd  0x0000FFFF,0x00CF9200
  ;; 因为GDT表的基地址和长度必须借助LGDT汇编指令才能加载到GDTR寄存器，
  ;; 而GDTR寄存器是一个6 B的结构，结构中的低2 B保存GDT表的长度，
  ;; 高4 B保存GDT表的基地址，标识符GdtPtr是此结构的起始地址。
  ;; 这个GDT表曾经用于开启Big Real Mode模式，
  ;; 由于其数据段被设置成平坦地址空间（0～4 GB地址空间），
  ;; 故此FS段寄存器可以寻址整个4 GB内存地址空间
GdtLen  equ $ - LABEL_GDT
GdtPtr  dw  GdtLen - 1
  dd  LABEL_GDT
  ;; 代码中的标识符SelectorCode32和SelectorData32是两个段选择子（Selector），
  ;; 它们是段描述符在GDT表中的索引号
SelectorCode32  equ LABEL_DESC_CODE32 - LABEL_GDT
SelectorData32  equ LABEL_DESC_DATA32 - LABEL_GDT

  ;; 为了切换到IA-32e模式而准备的临时GDT表结构数据
[SECTION gdt64]

LABEL_GDT64:    dq  0x0000000000000000
LABEL_DESC_CODE64:  dq  0x0020980000000000
LABEL_DESC_DATA64:  dq  0x0000920000000000

GdtLen64  equ $ - LABEL_GDT64
GdtPtr64  dw  GdtLen64 - 1
    dd  LABEL_GDT64

SelectorCode64  equ LABEL_DESC_CODE64 - LABEL_GDT64
SelectorData64  equ LABEL_DESC_DATA64 - LABEL_GDT64



  ;; 内存地址0x7E00是内核程序的临时转存空间，
  ;; 由于内核程序的读取操作是通过BIOS中断服务程序INT 13h实现的，
  ;; BIOS在实模式下只支持上限为1 MB的物理地址空间寻址，
  ;; 所以必须先将内核程序读入到临时转存空间，
  ;; 然后再通过特殊方式搬运到1 MB以上的内存空间中。
  ;; 当内核程序被转存到最终内存空间后，这个临时转存空间就可另作他用，
  ;; 此处将其改为内存结构数据的存储空间，供内核程序在初始化时使用。
[SECTION .s16]
[BITS 16]           ;BITS伪指令可以通知NASM编译器生成的代码，
                    ;将运行在16位宽的处理器上或者运行在32位宽的处理器上
  ;; 当NASM编译器处于16位宽（'BITS 16'）状态下，
  ;; 使用32位宽数据指令时需要在指令前加入前缀0x66，
  ;; 使用32位宽地址指令时需要在指令前加入前缀0x67。

Label_Start:

  mov ax, cs
  mov ds, ax
  mov es, ax
  mov ax, 0x00
  mov ss, ax
  mov sp, 0x7c00

;=======  display on screen : Start Loader......

  mov ax, 1301h
  mov bx, 000fh
  mov dx, 0300h   ;row 3
  mov cx, 12
  push  ax
  mov ax, ds
  mov es, ax
  pop ax
  mov bp, StartLoaderMessage
  int 10h

  ;; 开启1 MB以上物理地址寻址功能，同时开启实模式下的4 GB寻址功能
;=======  open address A20
  push  ax
  in  al, 92h
  or  al, 00000010b
  out 92h,  al
  pop ax

  cli                           ;关闭外部中断

  db  0x66
  lgdt  [GdtPtr]                ;加载保护模式结构数据信息

  mov eax,  cr0                 ;置位CR0寄存器的第0位来开启保护模式
  or  eax,  1
  mov cr0,  eax

  mov ax, SelectorData32
  mov fs, ax                    ;借助FS段寄存器的特殊寻址能力，
                                ;就可将内核程序移动到1 MB以上的内存地址空间中
  mov eax,  cr0
  and al, 11111110b
  mov cr0,  eax

  sti

;=======        reset floppy

        xor     ah,     ah
        xor     dl,     dl
        int     13h

;=======        search kernel.bin
        mov     word    [SectorNo],     SectorNumOfRootDirStart

Lable_Search_In_Root_Dir_Begin:

        cmp     word    [RootDirSizeForLoop],   0
        jz      Label_No_LoaderBin
        dec     word    [RootDirSizeForLoop]
        mov     ax,     00h
        mov     es,     ax
        mov     bx,     8000h
        mov     ax,     [SectorNo]
        mov     cl,     1
        call    Func_ReadOneSector
        mov     si,     KernelFileName
        mov     di,     8000h
        cld
        mov     dx,     10h

Label_Search_For_LoaderBin:

        cmp     dx,     0
        jz      Label_Goto_Next_Sector_In_Root_Dir
        dec     dx
        mov     cx,     11

Label_Cmp_FileName:

        cmp     cx,     0
        jz      Label_FileName_Found
        dec     cx
        lodsb
        cmp     al,     byte    [es:di]
        jz      Label_Go_On
        jmp     Label_Different

Label_Go_On:

        inc     di
        jmp     Label_Cmp_FileName

Label_Different:

        and     di,     0FFE0h
        add     di,     20h
        mov     si,     KernelFileName
        jmp     Label_Search_For_LoaderBin

Label_Goto_Next_Sector_In_Root_Dir:

        add     word    [SectorNo],     1
        jmp     Lable_Search_In_Root_Dir_Begin

;=======        display on screen : ERROR:No KERNEL Found

Label_No_LoaderBin:

        mov     ax,     1301h
        mov     bx,     008Ch
        mov     dx,     0400h           ;row 4
        mov     cx,     21
        push    ax
        mov     ax,     ds
        mov     es,     ax
        pop     ax
        mov     bp,     NoLoaderMessage
        int     10h
        jmp     $

;=======  found loader.bin name in root director struct
  ;; 这部分程序负责将内核程序读取到临时转存空间中，
  ;; 随后再将其移动至1 MB以上的物理内存空间
Label_FileName_Found:
  mov ax, RootDirSectors
  and di, 0FFE0h
  add di, 01Ah
  mov cx, word  [es:di]
  push  cx
  add cx, ax
  add cx, SectorBalance
  mov eax,  BaseTmpOfKernelAddr ;BaseOfKernelFile
  mov es, eax
  mov bx, OffsetTmpOfKernelFile ;OffsetOfKernelFile
  mov ax, cx

Label_Go_On_Loading_File:
  push  ax
  push  bx
  mov ah, 0Eh
  mov al, '.'
  mov bl, 0Fh
  int 10h
  pop bx
  pop ax

  mov cl, 1
  call  Func_ReadOneSector
  pop ax

;;;;;;;;;;;;;;;;;;;;;;;
  push  cx
  push  eax
  push  fs
  push  edi
  push  ds
  push  esi

  mov cx, 200h
  mov ax, BaseOfKernelFile
  mov fs, ax
  mov edi,  dword [OffsetOfKernelFileCount]

  mov ax, BaseTmpOfKernelAddr
  mov ds, ax
  mov esi,  OffsetTmpOfKernelFile

Label_Mov_Kernel: ;------------------
  ;; 为了避免转存环节发生错误，还是一个字节一个字节的复制为妙
  mov al, byte  [ds:esi]
  mov byte  [fs:edi], al

  inc esi
  inc edi

  loop  Label_Mov_Kernel

  mov eax,  0x1000
  mov ds, eax
  ;; 每次转存内核程序片段时必须保存目标偏移值，
  ;; 该值（EDI寄存器）保存于临时变量OffsetOfKernelFileCount中
  mov dword [OffsetOfKernelFileCount],  edi

  pop esi
  pop ds
  pop edi
  pop fs
  pop eax
  pop cx
;;;;;;;;;;;;;;;;;;;;;;;

  call  Func_GetFATEntry
  cmp ax, 0FFFh
  jz  Label_File_Loaded
  push  ax
  mov dx, RootDirSectors
  add ax, dx
  add ax, SectorBalance

  jmp Label_Go_On_Loading_File

Label_File_Loaded:

  mov ax, 0B800h
  mov gs, ax
  mov ah, 0Fh       ; 0000: 黑底    1111: 白字
  mov al, 'G'
  mov [gs:((80 * 0 + 39) * 2)], ax  ; 屏幕第 0 行, 第 39 列。


  ;; 关闭软驱马达
KillMotor:

  push  dx
  mov dx, 03F2h
  mov al, 0
  out dx, al
  pop dx

  ;; 当内核程序不再借助临时转存空间后，
  ;; 这块临时转存空间将用于保存物理地址空间信息

;=======  get memory address size type

  mov ax, 1301h
  mov bx, 000Fh
  mov dx, 0500h   ;row 5
  mov cx, 24
  push  ax
  mov ax, ds
  mov es, ax
  pop ax
  mov bp, StartGetMemStructMessage
  int 10h

  mov ebx,  0
  mov ax, 0x00
  mov es, ax
  mov di, MemoryStructBufferAddr
  ;; 物理地址空间信息由一个结构体数组构成，
  ;; 计算机平台的地址空间划分情况都能从这个结构体数组中反映出来，
  ;; 它记录的地址空间类型包括可用物理内存地址空间、
  ;; 设备寄存器地址空间、内存空洞等
Label_Get_Mem_Struct:

  mov eax,  0x0E820
  mov ecx,  20
  mov edx,  0x534D4150
  int 15h  ;借助BIOS中断服务程序INT 15h来获取物理地址空间信息，
           ;并将其保存在0x7E00地址处的临时转存空间里，
           ;操作系统会在初始化内存管理单元时解析该结构体数组
  jc  Label_Get_Mem_Fail
  add di, 20

  cmp ebx,  0
  jne Label_Get_Mem_Struct
  jmp Label_Get_Mem_OK

Label_Get_Mem_Fail:

  mov ax, 1301h
  mov bx, 008Ch
  mov dx, 0600h   ;row 6
  mov cx, 23
  push  ax
  mov ax, ds
  mov es, ax
  pop ax
  mov bp, GetMemStructErrMessage
  int 10h
  jmp $

Label_Get_Mem_OK:

  mov ax, 1301h
  mov bx, 000Fh
  mov dx, 0700h   ;row 7
  mov cx, 29
  push  ax
  mov ax, ds
  mov es, ax
  pop ax
  mov bp, GetMemStructOKMessage
  int 10h

                                ;=======        get SVGA information

  mov     ax,     1301h
  mov     bx,     000Fh
  mov     dx,     0900h           ;row 9
  mov     cx,     23
  push    ax
  mov     ax,     ds
  mov     es,     ax
  pop     ax
  mov     bp,     StartGetSVGAVBEInfoMessage
  int     10h

  mov     ax,     0x00
  mov     es,     ax
  mov     di,     0x8000
  mov     ax,     4F00h

  int     10h

  cmp     ax,     004Fh

  jz      .KO

;=======        Fail

  mov     ax,     1301h
  mov     bx,     008Ch
  mov     dx,     0B00h           ;row 11
  mov     cx,     23
  push    ax
  mov     ax,     ds
  mov     es,     ax
  pop     ax
  mov     bp,     GetSVGAVBEInfoErrMessage
  int     10h

  jmp     $

.KO:

  mov     ax,     1301h
  mov     bx,     000Fh
  mov     dx,     0B00h           ;row 11
  mov     cx,     29
  push    ax
  mov     ax,     ds
  mov     es,     ax
  pop     ax
  mov     bp,     GetSVGAVBEInfoOKMessage
  int     10h

;=======        Get SVGA Mode Info

  mov     ax,     1301h
  mov     bx,     000Fh
  mov     dx,     0D00h           ;row 13
  mov     cx,     24
  push    ax
  mov     ax,     ds
  mov     es,     ax
  pop     ax
  mov     bp,     StartGetSVGAModeInfoMessage
  int     10h


  mov     ax,     0x00
  mov     es,     ax
  mov     si,     0x800e

  mov     esi,    dword   [es:si]
  mov     edi,    0x8200

Label_SVGA_Mode_Info_Get:

  mov     cx,     word    [es:esi]

;=======        display SVGA mode information

  push    ax

  mov     ax,     00h
  mov     al,     ch
  call    Label_DispAL

  mov     ax,     00h
  mov     al,     cl
  call    Label_DispAL

  pop     ax

;=======

  cmp     cx,     0FFFFh
  jz      Label_SVGA_Mode_Info_Finish

  mov     ax,     4F01h
  int     10h

  cmp     ax,     004Fh

  jnz     Label_SVGA_Mode_Info_FAIL

  add     esi,    2
  add     edi,    0x100

  jmp     Label_SVGA_Mode_Info_Get

Label_SVGA_Mode_Info_FAIL:

  mov     ax,     1301h
  mov     bx,     008Ch
  mov     dx,     0F00h           ;row 15
  mov     cx,     24
  push    ax
  mov     ax,     ds
  mov     es,     ax
  pop     ax
  mov     bp,     GetSVGAModeInfoErrMessage
  int     10h

Label_SET_SVGA_Mode_VESA_VBE_FAIL:

  jmp     $

Label_SVGA_Mode_Info_Finish:

  mov     ax,     1301h
  mov     bx,     000Fh
  mov     dx,     0F00h           ;row 15
  mov     cx,     30
  push    ax
  mov     ax,     ds
  mov     es,     ax
  pop     ax
  mov     bp,     GetSVGAModeInfoOKMessage
  int     10h

;=======        set the SVGA mode(VESA VBE)

  mov     ax,     4F02h
  mov     bx,     4180h   ;========================mode : 0x180 or 0x143
  int     10h

  cmp     ax,     004Fh
  jnz     Label_SET_SVGA_Mode_VESA_VBE_FAIL

;=======        init IDT GDT goto protect mode
  ;; 为了进入保护模式，处理器必须在模式切换前，
  ;; 在内存中创建一段可在保护模式下执行的代码以及必要的系统数据结构，
  ;; 只有这样才能保证模式切换的顺利完成
  ;;
  ;; 相关系统数据结构包括IDT/GDT/LDT描述符表各一个（LDT表可选）、
  ;; 任务状态段TSS结构、至少一个页目录和页表（如果开启分页机制）
  ;; 和至少一个异常/中断处理模块
  ;;
  ;;在处理器切换到保护模式前，还必须初始化GDTR寄存器、
  ;;IDTR寄存器（亦可推迟到进入保护模式后，使能中断前）、
  ;;控制寄存器CR1～4、MTTRs内存范围类型寄存器
  ;;
  ;;在处理器切换至保护模式前，引导加载程序已使用CLI指令禁止外部中断，
  ;;所以在切换到保护模式的过程中不会产生中断和异常，进而不必完整地初始化IDT，
  ;;只要有相应的结构体即可。
  ;;如果能够保证处理器在模式切换的过程中不会产生异常，即使没有IDT也可以。

;; 处理器从实模式进入保护模式的契机是，
;; 执行MOV汇编指令置位CR0控制寄存器的PE标志位
;; （可同时置位CR0寄存器的PG标志位以开启分页机制）
;1. 执行CLI汇编指令禁止可屏蔽硬件中断，
;对于不可屏蔽中断NMI只能借助外部电路才能禁止。
;（模式切换程序必须保证在切换过程中不能产生异常和中断。）
;
;2. 执行LGDT汇编指令将GDT的基地址和长度加载到GDTR寄存器。
;
;3. 执行MOV CR0汇编指令位置CR0控制寄存器的PE标志位。
;（可同时置位CR0控制寄存器的PG标志位。）
;
;4. 一旦MOV CR0汇编指令执行结束，紧随其后必须执行一条远跳转（far JMP）
;或远调用（far CALL）指令，以切换到保护模式的代码段去执行。
;（这是一个典型的保护模式切换方法。）
;
;5. 通过执行JMP或CALL指令，可改变处理器的执行流水线，
;进而使处理器加载执行保护模式的代码段。
;
;6. 如果开启分页机制，那么MOV CR0指令和JMP/CALL（跳转/调用）指令
;必须位于同一性地址映射的页面内。（因为保护模式和分页机制使能后的物理地址，
;与执行JMP/CALL指令前的线性地址相同。）至于JMP或CALL指令的目标地址，
;则无需进行同一性地址映射（线性地址与物理地址重合）。
;
;7. 如需使用LDT，则必须借助LLDT汇编指令将GDT内的LDT段选择子加载到LDTR寄存器中。
;
;8. 执行LTR汇编指令将一个TSS段描述符的段选择子加载到TR任务寄存器。
;处理器对TSS段结构无特殊要求，凡是可写的内存空间均可。
;
;9. 进入保护模式后，数据段寄存器仍旧保留着实模式的段数据，
;必须重新加载数据段选择子或使用JMP/CALL指令执行新任务，便可将其更新为保护模式。
;（执行步骤(4)的JMP或CALL指令已将代码段寄存器更新为保护模式。）
;对于不使用的数据段寄存器（DS和SS寄存器除外），可将NULL段选择子加载到其中。
;
;10. 执行LIDT指令，将保护模式下的IDT表的基地址和长度加载到IDTR寄存器。
;
;11. 执行STI指令使能可屏蔽硬件中断，并执行必要的硬件操作使能NMI不可屏蔽中断。

  cli                     ;======close interrupt

  db      0x66
  lgdt    [GdtPtr]

  ;db      0x66
  ;lidt    [IDT_POINTER]

  mov     eax,    cr0
  or      eax,    1
  mov     cr0,    eax

  jmp     dword SelectorCode32:GO_TO_TMP_Protect

[SECTION .s32]
[BITS 32]

GO_TO_TMP_Protect:

;=======        go to tmp long mode 准备进入长模式
;一旦进入保护模式，首要任务是初始化各个段寄存器以及栈指针，
;然后检测处理器是否支持IA-32e模式（或称长模式）。
;如果不支持IA-32e模式就进入待机状态，不做任何操作。
;如果支持IA-32e模式，则开始向IA-32e模式切换。

  mov     ax,     0x10
  mov     ds,     ax
  mov     es,     ax
  mov     fs,     ax
  mov     ss,     ax
  mov     esp,    7E00h

  call    support_long_mode
  test    eax,    eax

  jz      no_support

;如果处理器支持IA-32e模式，接下来将为IA-32e模式配置临时页目录项和页表项
;=======        init temporary page table 0x90000

  ;; 将IA-32e模式的页目录首地址设置在0x90000地址处，
  ;; 并相继配置各级页表项的值（该值由页表起始地址和页属性组成）
  mov     dword   [0x90000],      0x91007
  mov     dword   [0x90800],      0x91007
  mov     dword   [0x91000],      0x92007
  mov     dword   [0x92000],      0x000083
  mov     dword   [0x92008],      0x200083
  mov     dword   [0x92010],      0x400083
  mov     dword   [0x92018],      0x600083
  mov     dword   [0x92020],      0x800083
  mov     dword   [0x92028],      0xa00083

;=======        load GDTR
  ;; 重新加载全局描述符表GDT，并初始化大部分段寄存器
  db      0x66
  lgdt    [GdtPtr64]
  mov     ax,     0x10
  mov     ds,     ax
  mov     es,     ax
  mov     fs,     ax
  mov     gs,     ax
  mov     ss,     ax

  mov     esp,    7E00h

;=======        open PAE

  mov     eax,    cr4
  bts     eax,    5
  mov     cr4,    eax

;=======        load    cr3

  mov     eax,    0x90000
  mov     cr3,    eax

;=======        enable long-mode

  mov     ecx,    0C0000080h              ;IA32_EFER
  rdmsr

  bts     eax,    8
  wrmsr

;=======        open PE and paging

  mov     eax,    cr0
  bts     eax,    0
  bts     eax,    31
  mov     cr0,    eax

  jmp     SelectorCode64:OffsetOfKernelFile

;=======        test support long mode or not

support_long_mode:

  mov     eax,    0x80000000
  cpuid
  cmp     eax,    0x80000001
  setnb   al
  jb      support_long_mode_done
  mov     eax,    0x80000001
  cpuid
  bt      edx,    29
  setc    al
support_long_mode_done:

  movzx   eax,    al
  ret

;=======        no support

no_support:
  jmp     $

;=======  read one sector from floppy

[SECTION .s16lib]
[BITS 16]

Func_ReadOneSector:

  push  bp
  mov bp, sp
  sub esp,  2
  mov byte  [bp - 2], cl
  push  bx
  mov bl, [BPB_SecPerTrk]
  div bl
  inc ah
  mov cl, ah
  mov dh, al
  shr al, 1
  mov ch, al
  and dh, 1
  pop bx
  mov dl, [BS_DrvNum]
Label_Go_On_Reading:
  mov ah, 2
  mov al, byte  [bp - 2]
  int 13h
  jc  Label_Go_On_Reading
  add esp,  2
  pop bp
  ret

;=======  get FAT Entry

Func_GetFATEntry:

  push  es
  push  bx
  push  ax
  mov ax, 00
  mov es, ax
  pop ax
  mov byte  [Odd],  0
  mov bx, 3
  mul bx
  mov bx, 2
  div bx
  cmp dx, 0
  jz  Label_Even
  mov byte  [Odd],  1

Label_Even:

  xor dx, dx
  mov bx, [BPB_BytesPerSec]
  div bx
  push  dx
  mov bx, 8000h
  add ax, SectorNumOfFAT1Start
  mov cl, 2
  call  Func_ReadOneSector

  pop dx
  add bx, dx
  mov ax, [es:bx]
  cmp byte  [Odd],  1
  jnz Label_Even_2
  shr ax, 4

Label_Even_2:
  and ax, 0FFFh
  pop bx
  pop es
  ret

;=======  display num in al
;通过这个程序模块可将十六进制数值显示在屏幕上
Label_DispAL:

  push  ecx
  push  edx
  push  edi

  mov edi,  [DisplayPosition]
  mov ah, 0Fh
  mov dl, al
  shr al, 4
  mov ecx, 2
.begin:

  and al, 0Fh
  cmp al, 9
  ja  .1
  add al, '0'
  jmp .2
.1:

  sub al, 0Ah
  add al, 'A'
.2:

  mov [gs:edi], ax
  add edi,  2

  mov al, dl
  loop  .begin

  mov [DisplayPosition],  edi

  pop edi
  pop edx
  pop ecx

  ret

;=======  tmp IDT
;除了必须为GDT手动创建初始数据结构外，还需要为IDT开辟内存空间

IDT:
  times 0x50  dq  0
IDT_END:

IDT_POINTER:
    dw  IDT_END - IDT - 1
    dd  IDT


;=======  tmp variable

RootDirSizeForLoop  dw  RootDirSectors
SectorNo    dw  0
Odd     db  0
OffsetOfKernelFileCount dd  OffsetOfKernelFile

DisplayPosition   dd  0


;=======  display messages

  StartLoaderMessage: db  "Start Loader"
  NoLoaderMessage:  db  "ERROR:No KERNEL Found"
  KernelFileName:   db  "KERNEL  BIN",0
  StartGetMemStructMessage: db  "Start Get Memory Struct."
  GetMemStructErrMessage: db  "Get Memory Struct ERROR"
  GetMemStructOKMessage:  db  "Get Memory Struct SUCCESSFUL!"

  StartGetSVGAVBEInfoMessage: db  "Start Get SVGA VBE Info"
  GetSVGAVBEInfoErrMessage: db  "Get SVGA VBE Info ERROR"
  GetSVGAVBEInfoOKMessage:  db  "Get SVGA VBE Info SUCCESSFUL!"

  StartGetSVGAModeInfoMessage:  db  "Start Get SVGA Mode Info"
  GetSVGAModeInfoErrMessage:  db  "Get SVGA Mode Info ERROR"
  GetSVGAModeInfoOKMessage: db  "Get SVGA Mode Info SUCCESSFUL!"
