#include <stdarg.h>

#include "printk.h"
#include "lib.h"
#include "linkage.h"

void putchar(unsigned int *fb, int Xsize, int x, int y, unsigned int FRcolor,
             unsigned int BKcolor, unsigned char font) {
  int i = 0,j = 0;
  unsigned int *addr = NULL;
  unsigned char * fontp = NULL;
  int testval = 0;
  fontp = font_ascii[font];

  for (i = 0;i < 16;++i) {
    addr = fb + Xsize * (y + i) + x;
    testval = 0x100;
    for (j = 0;j < 8;j++) {
      testval = testval >> 1;
      if (*fontp & testval)
        *addr = FRcolor;
      else
        *addr = BKcolor;
      addr++;
    }
    fontp++;
  }
}

int skip_atoi(const char **s);

static char *number(char *str, long num, int base, int size, int precision,
                    int type);

int vsprintf(char *buf, const char *fmt, va_list args) {

}

int color_printk(unsigned int FRcolor, unsigned int BKcolor, const char *fmt,
                 ...) {
  int i = 0;
  int count = 0;
  int line = 0;

  va_list args;
  va_start(args, fmt);
  i = vsprintf(buf, fmt, args);
  va_end(args);

  for (count = 0; count < i || line; count++) {
    // add \n \b \t
    if (line > 0) {
      count--;
      goto Label_tab;
    }
    if ((unsigned char)*(buf + count) == '\n') {
      Pos.YPosition++; // 换行
      Pos.XPosition = 0;
    } else if ((unsigned char)*(buf + count) == '\b') {
      Pos.XPosition--; // 退格
      if (Pos.XPosition < 0) {
        Pos.XPosition = (Pos.XResolution / Pos.XCharSize - 1) * Pos.XCharSize;
        Pos.YPosition--;
        if (Pos.YPosition < 0) {
          Pos.YPosition = (Pos.YResolution / Pos.YCharSize - 1) * Pos.YCharSize;
        }
        putchar(Pos.FB_addr, Pos.XResolution, Pos.XPosition * Pos.XCharSize,
          Pos.YPosition * Pos.YCharSize, FRcolor, BKcolor, ' ');
      }
    } else if ((unsigned char)*(buf + count) == '\t') {
      line = ((Pos.XPosition + 8) & ~(8 - 1)) - Pos.XPosition;
    Label_tab:
      line--;
      putchar(Pos.FB_addr, Pos.XResolution, Pos.XPosition * Pos.XCharSize,
              Pos.YPosition * Pos.YCharSize, FRcolor, BKcolor, ' ');
      Pos.XPosition++;
    } else {
      putchar(Pos.FB_addr, Pos.XResolution, Pos.XPosition * Pos.XCharSize,
              Pos.YPosition * Pos.YCharSize, FRcolor, BKcolor,
              (unsigned char)*(buf + count));
      Pos.XPosition++;
    }
    if (Pos.XPosition >= (Pos.XResolution / Pos.XCharSize)) {
      Pos.YPosition++;
      Pos.XPosition = 0;
    }
    if (Pos.YPosition >= (Pos.YResolution / Pos.YCharSize)) {
      Pos.YPosition = 0;
    }
  }
  return i;
}
