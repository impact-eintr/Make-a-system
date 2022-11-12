void Start_Kernel(void) {
  int *addr = (int *)0xffff800000a00000;
  int i;

  for (i = 0;i < 1440*20;i++) { // red 0x00ff0000
    *((char *)addr+0) = (char)0x00;
    *((char *)addr+1) = (char)0x00;
    *((char *)addr+2) = (char)0xff;
    *((char *)addr+3) = (char)0x00;
    addr += 1;
  }
  for (i = 0;i < 1440*20;i++) { // green 0x0000ff00
    *((char *)addr+0) = (char)0x00;
    *((char *)addr+1) = (char)0xff;
    *((char *)addr+2) = (char)0x00;
    *((char *)addr+3) = (char)0x00;
    addr += 1;
  }
  for (i = 0;i < 1440*20;i++) { // blue 0x000000ff
    *((char *)addr+0) = (char)0xff;
    *((char *)addr+1) = (char)0x00;
    *((char *)addr+2) = (char)0x00;
    *((char *)addr+3) = (char)0x00;
    addr += 1;
  }
  for (i = 0;i < 1440*20;i++) { // white 0x00ffffff
    *((char *)addr+0) = (char)0xff;
    *((char *)addr+1) = (char)0xff;
    *((char *)addr+2) = (char)0xff;
    *((char *)addr+3) = (char)0x00;
    addr += 1;
  }

  while(1) {
    ;
  }
}
