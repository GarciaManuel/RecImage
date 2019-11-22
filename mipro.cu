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

#define ThreadsPerBlock 24
#define MaxBlocks 128

/*
Calculation of Matrix multiplciation using C++ CUDA
*/

__device__ void similar(int col, int row, float *d_matrizE, int mE_x, int mE_y, float *d_matrizD, int mD_x, int mD_y, float *d_result, int r_x, int r_y, float percentage_num){
    // Get our current index at the resultant matrix
    int index = col + row * r_x;

    //Indexes helpers for the original matrix value
    int current = 0;
    int current_x = 0;
    int current_y = 0;

    //Current value of a rotation at 0 degrees and 180º degrees
    float rotation = 0.0;
    float rotation3 = 0.0;

    d_result[index] = 0;

    //Indexes for the 180 degrees
    int x = mD_x;
    int y = mD_y;

    for(int i = 0; i < mD_y; i ++){
        //Indexes actualization for the 180 degrees
        y = y -1;
        x= mD_x;
        for(int j = 0; j < mD_x; j ++){
            //Get current index for the original matrix
            current_x = (col + j);
            current_y = (row + i);

            //Indexes actualization for the 180 degrees
            x = x - 1;
            if(current_x < mE_x && current_y <mE_y){

                current = current_x + (current_y*(mE_x));
                //Offset from the user
                float offset1 = d_matrizD[j + i*mD_x] * percentage_num;
                //If between offset add 1
                if (d_matrizE[current] >= (d_matrizD[j + i*mD_x] + (offset1)) && d_matrizE[current] <= (d_matrizD[j + i*mD_x] - (offset1))) {
                    rotation += 1;

                }

                //Offset from the user
                float offset2 = d_matrizD[x + y*mD_x] * percentage_num;
                //If between offset add 1
                if (d_matrizE[current] >= (d_matrizD[x + y*mD_x]) + (offset2) &&  d_matrizE[current] <= (d_matrizD[x + y*mD_x]) - (offset2) ) {
                    rotation3 += 1;

                }


            }

        }
    }
    rotation = rotation/(mD_x*mD_y);
    rotation3 = rotation3/(mD_x*mD_y);
    //Check each rotation and get the value of max one
    if(rotation3 > rotation)
        d_result[index] = rotation3;
    else
        d_result[index] = rotation;


}

__global__ void valid_similarity(float *d_matrizE, int mE_x, int mE_y, float *d_matrizD, int mD_x, int mD_y, float *d_result, int r_x, int r_y, float percentage_num){
    //Get threads location
    int col = threadIdx.x + blockIdx.x * blockDim.x;
	int row = threadIdx.y + blockIdx.y * blockDim.y;

    //If the thread is located in the bounds of the resultant matrix the call similar to fill each cell of the resultant matrix
	if(r_y > row && r_x > col){
        similar(col, row, d_matrizE, mE_x, mE_y, d_matrizD, mD_x, mD_y, d_result, r_x, r_y, percentage_num);
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

    fin = fopen(file, "r");
    if (fin == NULL)
    {
        printf("File open error..");
        exit(0);
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

//Function to print matrix
void print_matriz(float *matriz, int x, int y){
    printf("\n");
    for(int i = 0; i<x; i++){
        for(int j = 0; j<y; j++){
            printf("%.3f \t",matriz[i + j*x]);
        }
        printf("\n");
    }
}
//Function to print matrix 90 degrees
void print_rotated(float *matriz, int x, int y){
    printf("\nRotated \n");
    for(int j = y-1; j>=0; j--){
        for(int i = 0; i<x; i++){
            printf("%.3f \t",matriz[i + j*x]);
        }
        printf("\n");
    }
}

//Function to print matrix 180 degrees
void print_rotated2(float *matriz, int x, int y){
    printf("\nRotated2 \n");
    for(int i = x-1; i>=0; i--){
        for(int j = y-1; j>=0; j--){
            printf("%.3f \t",matriz[i + j*x]);
        }
        printf("\n");
    }
}

//Function to print matrix 270 degrees
void print_rotated3(float *matriz, int x, int y){
    printf("\nRotated \n");
    for(int j = 0; j<y; j++){
        for(int i = x-1; i>=0; i--){
            printf("%.3f \t",matriz[i + j*x]);
        }
        printf("\n");
    }
}

//Function to get max result from matrix
float similarity(float *matriz, int x, int y){
    float max_res = 0.0;
    for(int i = 0; i<x; i++){
        for(int j = 0; j<y; j++){
            if (max_res < matriz[i + j*x]){
                max_res = matriz[i + j*x];
            }
        }
    }
    return max_res;
}

int main(int argc, char *argv[]){
    srand(time(NULL));   // Initialization, should only be called once. for the random
    close(0);
    //Receive params
    char *image;
    char *find;
    char *percentage;
    char *show_matrix;
    if (argc != 5)
    {
        printf("usage: %s initial_image_name image_to_find_name percentage_of_error show_resultant_matrix\n", argv[0]);
        return -1;
    }

    image = argv[1];
    find = argv[2];
    percentage = argv[3];
    show_matrix = argv[4];

    //Convert string to float form argv
    float percentage_num = atof(percentage);

    //Convert string to int form argv
    int show = atoi(show_matrix);

    //Declare ponters of cuda and C
    float *matrizE, *matrizD, *result;
    float *d_matrizE, *d_matrizD, *d_result;

    //Sizes of E & D
    int mE_x, mE_y, mD_x, mD_y;

    //Read each matrix
    matrizE = read_matrix(image, &mE_x, &mE_y);
    printf("\nOriginal image size \nWidth: %i, Height:%i \n", mE_y, mE_x);

    matrizD = read_matrix(find, &mD_x, &mD_y);
    printf("Image to find size \nWidth : %i, Height:%i \n", mD_y, mD_x);


    // Size of resultant matrix
    int r_x = mE_x;
    int r_y = mE_y;

    //Define blocks
    //int NumBlocks = (ThreadsPerBlock + (MaxBlocks*MaxBlocks-1))/ThreadsPerBlock;
    int NumBlocks = (ThreadsPerBlock + (r_x - 1))/ThreadsPerBlock;

    //Malloc resultant matrixes
    result = (float *)malloc(sizeof(float)*r_x*r_y);

    printf("\n");

    //Malloc in cuda for passing matrixes
    cudaMalloc((void**)&d_matrizE,sizeof(float)*mE_x*mE_y);
    cudaMalloc((void**)&d_matrizD,sizeof(float)*mD_x*mD_y);
    cudaMalloc((void**)&d_result,sizeof(float)*r_x*r_y);

    //Copy pointers of matrix e & d

    cudaMemcpy(d_matrizE, matrizE,sizeof(float)*mE_x*mE_y, cudaMemcpyHostToDevice);
    cudaMemcpy(d_matrizD, matrizD,sizeof(float)*mD_x*mD_y, cudaMemcpyHostToDevice);

    //Define sizes
    dim3 Blocks(NumBlocks,NumBlocks);
    dim3 Threads(ThreadsPerBlock,ThreadsPerBlock);


    printf("\nCalculating ... \n");

    //Take time for the cuda execution
    clock_t begin = clock();

    //Call Cuda global
    valid_similarity<<<Blocks, Threads>>>(d_matrizE, mE_x, mE_y, d_matrizD, mD_x, mD_y, d_result, r_x, r_y, percentage_num);

    clock_t end = clock();

    double time_spent = (double)(end - begin) / CLOCKS_PER_SEC;

    //Copy result
    cudaMemcpy(result, d_result,sizeof(float)*r_x*r_y, cudaMemcpyDeviceToHost);

    //Show result matrix if user wants
    printf("\n");
    if(show){
        printf("\nResultant matrix \n");
        print_matriz(result, r_x, r_y);

    }

    //Return value
    float percentage_similarity = similarity(result, r_x,r_y);
    printf("\nThe percentage of similarity with %s margin of error is: %f \n", argv[3], percentage_similarity);
    printf("Time spent: %f \n", time_spent);


    //Free all pointers
    free(matrizE);
    free(matrizD);
    free(result);

    //Free all pointers on device
    cudaFree(d_matrizE);
    cudaFree(d_matrizD);
    cudaFree(d_result);

}

