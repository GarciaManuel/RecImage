#include <stdio.h>
#include <stdlib.h>
#include <dirent.h>
#include <string.h>

int main(int argc, char* argv[]) {

  if (argc < 5) {
    fprintf(stderr, "usage: %s [Original image path] [Image to find path] [Error margin of similarity] [Flag to print result matrix]\n", argv[0]);
    return -1;
  }

  float errorMargin = atof(argv[3]);
  if (errorMargin < 0) {
    fprintf(stderr, "usage: %s Error margin of similaruty should be a positive float number\n", argv[0]);
    return -2;
  }

  if ( (strcmp(argv[4], "0") != 0 ) && (strcmp(argv[4], "1") != 0 )) {
    fprintf(stderr, "usage: %s Flag to print matrix should be 0 or 1\n", argv[0]);
    return -3;
  }

  char command [PATH_MAX * 2 + 20];
  snprintf(command, PATH_MAX*2+20, "java ImgIntoMatrix %s %s", argv[1], argv[2]);
  system(command);

  snprintf(command, PATH_MAX*2*2, "./mipro /home/A01701414/RecImage/original.txt /home/A01701414/RecImage/toFind.txt %s %s", argv[3], argv[4]);
  system(command);

  return 0;

}

