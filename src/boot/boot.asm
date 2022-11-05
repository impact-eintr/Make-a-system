  org 0x7c00                    ;起始地址

BaseOfStack equ 0x7c00          ;将标识符BaseOfStack等价为数值0x7c00

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

  jmp $

StartBootMessage: db  "Start Boot"
  ;; fill zero until whole sector
  times 510 - ($ - $$) db 0     ;表达式$ - $$的意思是，
                                ;将当前行被编译后的地址（机器码地址）
                                ;减去本节（Section）程序的起始地址
  dw 0xaa55
