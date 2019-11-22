# RecImage
Image Recognition with Java and CUDA

## Setup
  javac ImgIntoMatrix.java
  nvcc mipro.cu -o mipro
  gcc checkSimilarity.c -o checkSimilarity


## Run
./checkSimilarity ./pathOriginalImage ./pathImgTiFind [0...1] [0,1]

## Running Example
./checkSimilarity ./images/bearOriginal.jpg ./images/bearToFind.jpg 0.05 0


## Future releases
Image compression with ./compress program
Expected date: January 2020
