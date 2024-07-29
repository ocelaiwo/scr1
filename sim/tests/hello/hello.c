volatile unsigned long *htif = (unsigned long *)0x80001000;

int main()
{
  while (1) {
    *htif = 1;
  }
  return 0;
}
