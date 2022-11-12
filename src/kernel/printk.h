#ifndef PRINTK_H_
#define PRINTK_H_

#include <stdarg.h>

#include "lib.h"
#include "linkage.h"

#define ZEROPAD 1                              /* pad with zero */
#define SIGN 2                                 /* unsigned/signed long */
#define PLUS 4 /* show plus */ #define SPACE 8 /* space if plus */
#define LEFT 16                                /* left justified */
#define SPECIAL 32                             /* 0x */
#define SMALL 64 /* use 'abcdef' instead of 'ABCDEF' */

#define is_digit(c) ((c) >= '0' && (c) <= '9')

#define WHITE 0x00ffffff  //白
#define BLACK 0x00000000  //黑
#define RED 0x00ff0000    //红
#define ORANGE 0x00ff8000 //橙
#define YELLOW 0x00ffff00 //黄
#define GREEN 0x0000ff00  //绿
#define BLUE 0x000000ff   //蓝
#define INDIGO 0x0000ffff //靛
#define PURPLE 0x008000ff //紫

extern unsigned char font_ascii[256][16];

char buf[4096]={0};

struct position {
  int XResolution; // 总宽度
  int YResolution; // 总高度

  int XPosition; // (X, y)
  int YPosition; // (x, Y)

  int XCharSize; // 单个字符宽度
  int YCharSize; // 单个字符高度

  unsigned int * FB_addr;
  unsigned long FB_length;
} Pos;

void putchar(unsigned int *fb, int Xsize, int x, int y, unsigned int FRcolor,
             unsigned int BKcolor, unsigned char font);

int skip_atoi(const char **s);

// __asm__(汇编语句模板:输出部分:输入部分:破坏描述部分)
// = 表示这是一个输出操作数
// a 将变量放入eax
// d 将变量放入edx
// 0..9 表示用它限制的操作数与某个指定的操作数匹配
// 也即该操作数就是指定的那个操作数，例如"0"去描述"％1"操作数，
// 那么"%1"引用的其实就是"%0"操作数，注意作为限定符字母的0－9 与
// 指令中的"％0"－"％9"的区别，前者描述操作数，后者代表操作数。
#define do_div(n,base) ({\
int __res;\
__asm__("divq %%rcx":"=a" (n),"=d" (__res):"0" (n), "1" (0),"c" (base));\
__res;  })

static char * number(char *str, long num, int base, int size, int precision, int type);

int vsprintf(char *buf, const char *fmt, va_list args);

int color_printk(unsigned int FRcolor, unsigned int BKcolor, const char * fmt, ...);

#endif // PRINTK_H_
