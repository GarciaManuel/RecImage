
import javax.imageio.IIOException;
import javax.imageio.ImageIO;
import java.awt.image.BufferedImage;
import java.io.BufferedWriter;
import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.util.concurrent.ForkJoinPool;
import java.util.concurrent.RecursiveAction;

public class ImgIntoMatrix extends RecursiveAction {

    // Variables to handle the indexes and the image for the iteration of recursive action
    private BufferedImage img;
    private int[][] pix;
    private int colStart;
    private int rowEnd;
    private int colEnd;
    private static int sThreshold = 500;

    // Constructor, assigning initial values to variables
    private ImgIntoMatrix(int cs, int ce, int re, BufferedImage img, int[][] pix) {
        colStart = cs;
        colEnd = ce;
        rowEnd = re;
        this.pix = pix;
        this.img = img;
    }

    private void computeDirectly(){
        for (int i = 0; i < rowEnd; i++) {
            for (int j = colStart; j < colEnd; j++) {
                try {
                    pix[i][j] = img.getRGB(j , i);
                } catch (ArrayIndexOutOfBoundsException ae){
                    System.out.println(ae);
                }
            }
        }
    }

    @Override
    protected void compute() {
        if ((colEnd - colStart) < sThreshold) {
            computeDirectly();
            return;
        }

        int split = (colEnd + colStart) >> 1;
        invokeAll(new ImgIntoMatrix(colStart, split, rowEnd, img, pix),
                new ImgIntoMatrix(split, colEnd, rowEnd, img, pix));
    }

    public static void main(String args[]) throws IOException {

        if(args.length < 2){
            System.out.println("ImgIntoMatrix usage: pathToOriginalImage pathToImageToFind/-c");
            return;
        }

        try{
            String fileName = "original";

            if(args[1].equals("-c")) fileName = "imgToCompress";

            BufferedImage img = ImageIO.read(new File(args[0]));
            parallelMatrix(img, fileName);

            if(!args[1].equals("-c")){
                BufferedImage imgToFind = ImageIO.read(new File(args[1]));
                parallelMatrix(imgToFind, "toFind");
            }
        } catch (IIOException io){
            System.out.println("Error: ImgIntoMatrix - Can't read input file");
        }
    }

    private static void parallelMatrix(BufferedImage srcImg, String outputName)  {
        int w = srcImg.getWidth();
        int h = srcImg.getHeight();

        int[][] pix = new int[h][w];

        ImgIntoMatrix im = new ImgIntoMatrix(0, w, h, srcImg, pix);
        ForkJoinPool pool = new ForkJoinPool();

        System.out.println("\nParalleling image into matrix conversion");
        long startTime = System.currentTimeMillis();
        pool.invoke(im);
        long endTime = System.currentTimeMillis();
        System.out.println("Parallel image into matrix took " + (endTime - startTime) + " milliseconds.");
        pool.shutdown();

        writeMatrix(pix, outputName);
    }

    private static void sequentialMatrix(BufferedImage srcImg)  {

        System.out.println("SEQUENTIAL \n Starting sequential image into matrix");
        long startTime = System.currentTimeMillis();
        int width = srcImg.getWidth(null);
        int height = srcImg.getHeight(null);
        int[][] pixels = new int[width][height];
        for (int i = 0; i < width; i++) {
            for (int j = 0; j < height; j++) {
                pixels[i][j] = srcImg.getRGB(i, j);
            }
        }

        long endTime = System.currentTimeMillis();
        System.out.println("Sequential image into matrix took " + (endTime - startTime) + " milliseconds.\n");

        writeMatrix(pixels, "seq");
    }

    private static void writeMatrix(int[][] matrix, String name) {
        try {
            BufferedWriter bw = new BufferedWriter(new FileWriter("./" + name + ".txt"));

            bw.write(matrix.length + "," + matrix[0].length);
            bw.newLine();

            for (int i = 0; i < matrix.length; i++) {
                for (int j = 0; j < matrix[i].length; j++) {
                    bw.write(matrix[i][j] + ((j == matrix[i].length-1) ? "" : ","));
                }
                bw.write(",");
                bw.newLine();
            }
            bw.flush();
        } catch (IOException ignored) {}
    }
}
