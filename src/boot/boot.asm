;  org 0x7c00                    ;起始地址
;
;BaseOfStack equ 0x7c00          ;将标识符BaseOfStack等价为数值0x7c00
;
;Label_Start:
;
;  mov ax, cs                    ;将CS寄存器的段基地址设置到DS、ES、SS等寄存器中
;  mov ds, ax
;  mov es, ax
;  mov ss, ax
;  mov sp, BaseOfStack           ;设置栈指针寄存器SP
;
;  ;; clear screen
;  mov ax, 0600h                 ;AH=06h功能：按指定范围滚动窗口
;  mov bx, 0700h                 ;BH=滚动后空出位置放入的属性
;  mov cx, 0                     ;CH=滚动范围的左上角坐标列号
;                                ;CL=滚动范围的左上角坐标行号
;  mov dx, 0184fh                ;DH=滚动范围的右下角坐标列号
;                                ;DL=滚动范围的右下角坐标行号
;  int 10h                       ;BIOS中断服务程序INT 10h
;
;  ;; set focus
;  mov ax, 0200h                 ;AH=02 设定光标位置
;  mov bx, 0000h                 ;DH=游标的列数
;  mov dx, 0000h                 ;DH=游标的列数 DH=游标的列数
;  int 10h
;
;  ;; display on screen:Start Booting
;  mov ax, 1301h                 ;AH=13h功能：显示一行字符串
;                                ;AL=00h：字符串的属性由BL寄存器提供，
;                                ;而CX寄存器提供字符串长度（以B为单位），
;                                ;显示后光标位置不变，即显示前的光标位置。
;                                ;AL=01h：同AL=00h，
;                                ;但光标会移动至字符串尾端位置。
;                                ;AL=02h：字符串属性由每个字符后面紧跟的字节提供，
;                                ;故CX寄存器提供的字符串长度改成以Word为单位，
;                                ;显示后光标位置不变。
;                                ;AL=03h：同AL=02h，但光标会移动至字符串尾端位置。
;  mov bx, 000fh                 ;BL=字符属性/颜色属性
;  mov dx, 0000h                 ;DH=游标的坐标行号 DL=游标的坐标列号
;  mov cx, 10                    ;CX=字符串的长度。
;  push ax
;  mov ax, ds                    ;ES:BP=>要显示字符串的内存地址
;  mov es, ax
;  pop ax
;  mov bp, StartBootMessage
;  int 10h
;
;  ;; reset floppy
;  xor ah, ah                    ;AH=00h功能：重置磁盘驱动器，为下一次读写软盘做准备
;  xor dl, dl
;  int 13h
;
;  jmp $
;
;StartBootMessage: db  "Start Boot"
;  ;; fill zero until whole sector
;  times 510 - ($ - $$) db 0     ;表达式$ - $$的意思是，
;                                ;将当前行被编译后的地址（机器码地址）
;                                ;减去本节（Section）程序的起始地址
;  dw 0xaa55

  org 0x7c00

BaseOfStack equ  0x7c00

BaseOfLoader equ 0x1000
OffsetOfLoader equ 0x00

RootDirSectors  equ 14
SectorNumOfRootDirStart equ 19
SectorNumOfFAT1Start  equ 1
SectorBalance equ 17

  jmp short Label_Start
  nop
  BS_OEMName  db  'MINEboot'
  BPB_BytesPerSec dw  512
  BPB_SecPerClus  db  1
  BPB_RsvdSecCnt  dw  1
  BPB_NumFATs db  2
  BPB_RootEntCnt  dw  224
  BPB_TotSec16  dw  2880
  BPB_Media db  0xf0
  BPB_FATSz16 dw  9
  BPB_SecPerTrk dw  18
  BPB_NumHeads  dw  2
  BPB_HiddSec dd  0
  BPB_TotSec32  dd  0
  BS_DrvNum db  0
  BS_Reserved1  db  0
  BS_BootSig  db  0x29
  BS_VolID  dd  0
  BS_VolLab db  'boot loader'
  BS_FileSysType  db  'FAT12   '

Label_Start:

  mov ax, cs                    ;将CS寄存器的段基地址设置到DS、ES、SS等寄存器中
  mov ds, ax
  mov es, ax
  mov ss, ax
  mov sp, BaseOfStack           ;设置栈指针寄存器SP
  ;; clear screen
  mov ax, 0600h                 ;AH=06h功能：按指定范围滚动窗口
  mov bx, 0700h                 ;BH=滚动后空出位置放入的属性
  mov cx, 0                     ;CH=滚动范围的左上角坐标列号
                                ;CL=滚动范围的左上角坐标行号
  mov dx, 0184fh                ;DH=滚动范围的右下角坐标列号
                                ;DL=滚动范围的右下角坐标行号
  int 10h                       ;BIOS中断服务程序INT 10h

  ;; set focus
  mov ax, 0200h                 ;AH=02 设定光标位置
  mov bx, 0000h                 ;DH=游标的列数
  mov dx, 0000h                 ;DH=游标的列数 DH=游标的列数
  int 10h

  ;; display on screen:Start Booting
  mov ax, 1301h                 ;AH=13h功能：显示一行字符串
                                ;AL=00h：字符串的属性由BL寄存器提供，
                                ;而CX寄存器提供字符串长度（以B为单位），
                                ;显示后光标位置不变，即显示前的光标位置。
                                ;AL=01h：同AL=00h，
                                ;但光标会移动至字符串尾端位置。
                                ;AL=02h：字符串属性由每个字符后面紧跟的字节提供，
                                ;故CX寄存器提供的字符串长度改成以Word为单位，
                                ;显示后光标位置不变。
                                ;AL=03h：同AL=02h，但光标会移动至字符串尾端位置。
  mov bx, 000fh                 ;BL=字符属性/颜色属性
  mov dx, 0000h                 ;DH=游标的坐标行号 DL=游标的坐标列号
  mov cx, 10                    ;CX=字符串的长度。
  push ax
  mov ax, ds                    ;ES:BP=>要显示字符串的内存地址
  mov es, ax
  pop ax
  mov bp, StartBootMessage
  int 10h

  ;; reset floppy
  xor ah, ah                    ;AH=00h功能：重置磁盘驱动器，为下一次读写软盘做准备
  xor dl, dl
  int 13h

  ;❏ BS_OEMName。记录制造商的名字，亦可自行为文件系统命名
  ;❏ BPB_SecPerClus。描述了每簇扇区数。由于每个扇区的容量只有512 B，过小的扇区容量可能会导致软盘读写次数过于频繁，从而引入簇（Cluster）这个概念。簇将2的整数次方个扇区作为一个“原子”数据存储单元，也就是说簇是FAT类文件系统的最小数据存储单位。
  ;❏ BPB_RsvdSecCnt。指定保留扇区的数量，此域值不能为0。保留扇区起始于FAT12文件系统的第一个扇区，对于FAT12而言此位必须为1，也就意味着引导扇区包含在保留扇区内，所以FAT表从软盘的第二个扇区开始。
  ;❏ BPB_NumFATs。指定FAT12文件系统中FAT表的份数，任何FAT类文件系统都建议此域设置为2。设置为2主要是为了给FAT表准备一个备份表，因此FAT表1与FAT表2内的数据是一样的，FAT表2是FAT表1的数据备份表。
  ;❏ BPB_RootEntCnt。指定根目录可容纳的目录项数于FAT12文件系统而言，这个数值乘以32必须是BPB_BytesPerSec的偶数倍。
  ;❏ BPB_TotSec16。记录着总扇区数。这里的总扇区数包括保留扇区（内含引导扇区）、FAT表、根目录区以及数据区占用的全部扇区数，如果此域值为0，那么BPB_TotSec32字段必须是非0值。
  ;❏ BPB_Media。描述存储介质类型。对于不可移动的存储介质而言，标准值是0xF8。对于可移动的存储介质，常用值为0xF0，此域的合法值是0xF0、0xF8、0xF9、0xFA、0xFB、0xFC、0xFD、0xFE、0xFF。另外提醒一点，无论该字段写入了什么数值，同时也必须向FAT[0]的低字节写入相同值。
  ;❏ BPB_FATSz16。记录着FAT表占用的扇区数。FAT表1和FAT表2拥有相同的容量，它们的容量均由此值记录。
  ;❏ BS_VolLab。指定卷标。它就是Windows或Linux系统中显示的磁盘名。
  ;❏ BS_FileSysType。描述文件系统类型。此处的文件系统类型值为’FAT12 '，这个类型值只是一个字符串而已，操作系统并不使用该字段来鉴别FAT类文件系统的类型。

  ;; search loader.bin
  mov word [SectorNo], SectorNumOfRootDirStart

Lable_Search_In_Root_Dir_Begin:

  cmp word  [RootDirSizeForLoop], 0
  jz  Label_No_LoaderBin
  dec word  [RootDirSizeForLoop]
  mov ax, 00h
  mov es, ax
  mov bx, 8000h
  mov ax, [SectorNo]
  mov cl, 1
  call  Func_ReadOneSector
  mov si, LoaderFileName
  mov di, 8000h
  cld
  mov dx, 10h

Label_Search_For_LoaderBin:

  cmp dx, 0
  jz  Label_Goto_Next_Sector_In_Root_Dir
  dec dx
  mov cx, 11

Label_Cmp_FileName:
  ;; FAT12文件系统的文件名是不区分大小写字母的，
  ;; 即使将小写字母命名的文件复制到FAT12文件系统内，
  ;; 文件系统也会为其创建大写字母的文件名和目录项
  cmp cx, 0
  jz  Label_FileName_Found
  dec cx
  lodsb
  cmp al, byte  [es:di]
  jz  Label_Go_On
  jmp Label_Different

Label_Go_On:

  inc di
  jmp Label_Cmp_FileName

Label_Different:

  and di, 0ffe0h
  add di, 20h
  mov si, LoaderFileName
  jmp Label_Search_For_LoaderBin

Label_Goto_Next_Sector_In_Root_Dir:

  add word  [SectorNo], 1
  jmp Lable_Search_In_Root_Dir_Begin

;=======  display on screen : ERROR:No LOADER Found

Label_No_LoaderBin:

  mov ax, 1301h
  mov bx, 008ch
  mov dx, 0100h
  mov cx, 21
  push  ax
  mov ax, ds
  mov es, ax
  pop ax
  mov bp, NoLoaderMessage
  int 10h
  jmp $

;=======  found loader.bin name in root director struct

Label_FileName_Found:

  mov ax, RootDirSectors
  and di, 0ffe0h
  add di, 01ah
  mov cx, word  [es:di]
  push  cx
  add cx, ax
  add cx, SectorBalance
  mov ax, BaseOfLoader
  mov es, ax
  mov bx, OffsetOfLoader
  mov ax, cx

Label_Go_On_Loading_File:
  push  ax
  push  bx
  mov ah, 0eh
  mov al, '.'
  mov bl, 0fh
  int 10h
  pop bx
  pop ax

  mov cl, 1
  call  Func_ReadOneSector
  pop ax
  ;;
  call  Func_GetFATEntry
  cmp ax, 0fffh
  jz  Label_File_Loaded
  push  ax
  mov dx, RootDirSectors
  add ax, dx
  add ax, SectorBalance
  add bx, [BPB_BytesPerSec]
  jmp Label_Go_On_Loading_File

Label_File_Loaded:

  jmp BaseOfLoader:OffsetOfLoader

  ;; read one sector from floppy
  ;; AX 带读取的磁盘起始扇区号
  ;; CL=读入的扇区数量
  ;; ES:BX=>目标缓冲区起始地址
Func_ReadOneSector
  push bp
  mov bp, sp
  sub esp, 2
  mov byte [bp - 2], cl
  push bx
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
  and ax, 0fffh
  pop bx
  pop es
  ret

;=======  tmp variable

RootDirSizeForLoop  dw  RootDirSectors
SectorNo    dw  0
Odd     db  0


;=======  display messages

StartBootMessage: db  "Start Boot"
NoLoaderMessage:  db  "ERROR:No LOADER Found"
LoaderFileName:   db  "LOADER  BIN",0

;=======  fill zero until whole sector

  times 510 - ($ - $$)  db  0
  dw  0xaa55
