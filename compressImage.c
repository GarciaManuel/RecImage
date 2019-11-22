#include <stdio.h>
#include <stdlib.h>
#include <dirent.h>
#include <string.h>

int main(int argc, char* argv[]) {

  if (argc < 5) {
    fprintf(stderr, "usage: %s [Image to compress path] [Output file name] [X size for kernel] [Y size for kernel]\n", argv[0]);
    return -1;
  }

  int xKernel = atoi(argv[3]);
  int yKernel = atoi(argv[4]);

  if(xKernel < 2 || yKernel < 2) {
    fprintf(stderr, "usage: %s Both X and Y size for kernel must be an integer number greater than or equal to 2\n", argv[0]);
    return -2;
  }

  char command [PATH_MAX + 20];
  snprintf(command, PATH_MAX + 20, "java ImgIntoMatrix %s -c", argv[1]);
  system(command);

  snprintf(command, PATH_MAX + 20, "./compress /home/A01701414/project/imgToCompress.txt %s %s", argv[3], argv[4]);
  system(command);

  snprintf(command, PATH_MAX + 20, "java MatrixIntoImg /home/A01701414/project/compressedImage.txt %s", argv[1]);
  system(command);

  return 0;

}

