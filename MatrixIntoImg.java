
import javax.imageio.IIOException;
import javax.imageio.ImageIO;
import java.awt.image.BufferedImage;
import java.awt.image.WritableRaster;
import java.io.*;
import java.util.Arrays;
import java.util.Scanner;
import java.util.concurrent.ForkJoinPool;
import java.util.concurrent.RecursiveAction;

public class MatrixIntoImg {

    // Variables to handle the indexes and the image for the iteration of recursive action
    private static int[][] matrixImg;

    public static void main(String args[]) throws IOException {

        if(args.length != 2){
            System.out.println("MatrixIntoImg usage: pathToMatrix outPutFileName");
            return;
        }
        readMatrix(args[0]);
        intToImg(args[1]);
    }

    private static void intToImg(String path){
        int[][] pxls = matrixImg;

        BufferedImage image = new BufferedImage(pxls[0].length, pxls.length, BufferedImage.TYPE_INT_ARGB);
        for(int i=0; i < pxls.length; i++) {
            for(int j=0; j < pxls[0].length; j++) {
                image.setRGB(j, i, pxls[i][j]);
            }
        }

        try{
            File f = null;
            f = new File("./" + path + ".jpg");
            ImageIO.write(image, "png", f);
        } catch (IOException x){x.printStackTrace();}
    }

    private static void readMatrix(String path) throws FileNotFoundException {
        Scanner sc = new Scanner(new BufferedReader(new FileReader(path)));

        String[] firstLine = sc.nextLine().trim().split(",");

        int rows = Integer.parseInt(firstLine[0]);
        int columns = Integer.parseInt(firstLine[1]);
        int [][] myArray = new int[rows][columns];
        while(sc.hasNextLine()) {
            for (int i=0; i < myArray.length; i++) {
                String[] line = sc.nextLine().trim().split(",");
                for (int j=0; j<line.length; j++) {
                    myArray[i][j] = Integer.parseInt(line[j]);
                }
            }
        }
        matrixImg = myArray;
    }
}
