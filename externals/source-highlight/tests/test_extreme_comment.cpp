// test special #if 0 treatment

int main() {
#if 0 // equivalent to a comment
  int i = 10;
  printf("this should never be executed\n");
  return 1;
#else
  printf("Hello world!\n");
  return 0;
#endif

  printf("never reach here!\n");
}
