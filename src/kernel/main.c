#include "lib.h"
#include "printk.h"

void Start_Kernel(void) {
  Pos.XResolution = 1440;
  Pos.YResolution = 900;

  Pos.XPosition = 0;
  Pos.YPosition = 0;

  Pos.XCharSize = 8;
  Pos.YCharSize = 16;

  Pos.FB_addr = (unsigned int *)0xffff800000a00000;
  Pos.FB_length = (Pos.XResolution * Pos.YResolution * 4);

  color_printk(YELLOW, BLACK, "Hello\t\t World!\n");

  while(1) {
    ;
  }
}
