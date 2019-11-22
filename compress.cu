/*
 * A01701414_lab2.cu
 *
 *  Created on: 11/14/2019
 *      Author: Manuel Garcia
 *		ID: A01701414
*/
#include <time.h>
#include <stdio.h> 
#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/types.h>
#include <dirent.h>
#include <signal.h>
#include <string.h>
#include <sys/types.h>
#include <sys/stat.h>

#define ThreadsPerBlock 25


/*
Calculation of Matrix multiplciation using C++ CUDA
*/

__device__ void compress(int col, int row, float *d_matrizE, int mE_x, int mE_y, int mD_x, int mD_y, float *d_result, int r_x, int r_y){
    // Get our current index at the resultant matrix
    int index = col + row * r_x;

    int index_x = 0;
    int index_y = 0;
    int current = 0;

    float promedio = 0.0;
    int count = 0;

    //Iterate in the image matrix
    for(int i = 0; i < mD_y; i++){
        for(int j = 0; j < mD_x; j++){
            index_x = col + j;
            index_y = row + i;

            //Eval if index is within bounds
            if(index_x < mE_x && index_y <mE_y){
                current = index_x + index_y * mE_x;
                count += 1;
                //add up all cells in compress dimension
                promedio += d_matrizE[current];
            }
        }
    }

    //Divide the result by the number of items summed and put into the resultant matrix.
    d_result[index] = promedio/count;
    
}

__global__ void valid_compression(float *d_matrizE, int mE_x, int mE_y, int mD_x, int mD_y, float *d_result, int r_x, int r_y){
    //Get threads location
    int col = threadIdx.x + blockIdx.x * blockDim.x;
	int row = threadIdx.y + blockIdx.y * blockDim.y;

    //If the thread is located in the bounds of the resultant matrix the call compress to fill each cell of the resultant matrix
	if(r_y > row && r_x > col){
        compress(col, row, d_matrizE, mE_x, mE_y, mD_x, mD_y, d_result, r_x, r_y);

	}
}

//Function to fill randomly matrix with numbers up to 20
void fill_matriz(float *matriz, int x, int y){
    for(int i = 0; i<x; i++){
        for(int j = 0; j<y; j++){
            matriz[i + j*x] = rand()%20;
        }
    }
}
//Function to read each amtrix form a file and return the pointer
float *read_matrix(char *file, int *mx, int *my)
{
    
    FILE* fin;
    float *matriz;
    int x, y;

    printf("Opening the file...\n");
    fin = fopen(file, "r");
    if (fin == NULL)
    {
        printf("File open error..");
        exit(0);
    }
    else
    {
        printf("File opened successfully..");
    }

    //Read sizes of x and y
    fscanf(fin, "%i,", mx);
    fscanf(fin, "%i\n", my);

    x = *mx;
    y = *my;

    matriz = (float *)malloc(sizeof(float) * x * y);

    //Read each value
    for (int i = 0; i < x; i++)
    {
        for (int j = 0; j < y; j++)
        {
            fscanf(fin, "%f,", &matriz[i + j * x]);
        }
        fscanf(fin, "\n");
    }

    //close descriptor
    fclose(fin);

    return matriz;
}
//Function to write a matrix into the file compressedImage.txt
void write_file(float *matrix, int x, int y){
    FILE* fin;

    printf("Opening the file...\n");
    fin = fopen("compressedImage.txt", "w+");
    if (fin == NULL)
    {
        printf("File open error..");
        exit(0);
    }
    else
    {
        printf("File opened successfully..");
    }
     //Print sizes of x and y
     fprintf(fin, "%i,", x);
     fprintf(fin, "%i\n", y);

    //Print each value
    for (int i = 0; i < x; i++)
    {
        for (int j = 0; j < y; j++)
        {
            fprintf(fin, "%i,", (int)matrix[i + j * x]);
        }
        fprintf(fin, "\n");
    }

    //close descriptor
    fclose(fin);

}

//Function to print matrix
void print_matriz(float *matriz, int x, int y){
    printf("\n");
    for(int i = 0; i<x; i++){
        for(int j = 0; j<y; j++){
            printf("%.1f \t",matriz[i + j*x]);
        }
        printf("\n");
    }
}

int main(int argc, char *argv[]){
    srand(time(NULL));   // Initialization, should only be called once. for the random
    close(0);
    //Receive params
    char *image;
    char *dim_x;
    char *dim_y;

    if (argc != 4)
    {
        printf("usage: %s initial_image_name dim_x dim_y \n", argv[0]);
        return -1;
    }
    image = argv[1];
    dim_x = argv[2];
    dim_y = argv[3];

    //Declare ponters of cuda and C
    float *matrizE, *result;
    float *d_matrizE, *d_result;

    //Sizes of E & D
    int mE_x, mE_y, mD_x, mD_y;

    //Get sizes of matrix compression
    mD_x = atoi(dim_x);
    mD_y = atoi(dim_y);

    //Read E matrix
    matrizE = read_matrix(image, &mE_x, &mE_y);
    printf("x : %i, y:%i \n", mE_x, mE_y);

    // Size of resultant matrix
    int r_x = 1 + ((mE_x - 1) / mD_x);
    int r_y = 1 + ((mE_y - 1) / mD_y);
    
    //Define blocks
    int NumBlocks = (ThreadsPerBlock + (r_x - 1))/ThreadsPerBlock;

    //Malloc matrixes
    result = (float *)malloc(sizeof(float)*r_x*r_y);

    printf("Compress image \n");

    printf("Originals \nMatrix E:\n");

    printf("Size x : %i, size y: %i \n", mE_x, mE_y);

    printf("\n");
    printf("Matrix compression dims: x - %i\t y - %i\n", mD_x, mD_y);

    printf("\n");

    //Malloc in cuda for passing matrixes
    cudaMalloc((void**)&d_matrizE,sizeof(float)*mE_x*mE_y);
    cudaMalloc((void**)&d_result,sizeof(float)*r_x*r_y);

    //Copy pointers of matrix e & d

    cudaMemcpy(d_matrizE, matrizE,sizeof(float)*mE_x*mE_y, cudaMemcpyHostToDevice);

    //Define sizes fro cuda 
    dim3 Blocks(NumBlocks,NumBlocks);
    dim3 Threads(ThreadsPerBlock,ThreadsPerBlock);
    
    //Take time for the cuda execution
    clock_t begin = clock();

    //Call Cuda global
	valid_compression<<<Blocks, Threads>>>(d_matrizE, mE_x, mE_y, mD_x, mD_y, d_result, r_x, r_y);
    clock_t end = clock();

    double time_spent = (double)(end - begin) / CLOCKS_PER_SEC;

    //Copy result
    cudaMemcpy(result, d_result,sizeof(float)*r_x*r_y, cudaMemcpyDeviceToHost);

    printf("\n");
    printf("Resultant matrix:\n");
    write_file(result, r_x, r_y);
    printf("\nTime spent: %f \n", time_spent);



    //Free all pointers
    free(matrizE);
    free(result);
    
    //Free all pointers on device
    cudaFree(d_matrizE);
    cudaFree(d_result);

}

