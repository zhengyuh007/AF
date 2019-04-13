/*
****************************************************************************************
This CPP is written to calculate PD for two images(left from sensor and right from sensor)
Copyright: Zhengyu He
Date: April/12/2019
****************************************************************************************
*/
#include <stdio.h>#include <iostream>#include <stdlib.h>
#include <cstdlib>

using namespace std;

// minimal and max move for right image(unit: pixel)
const int min_move = -8;
const int max_move = 8;
// unsgined short is 16 bit (2bytes)
typedef unsigned short uint16;
//-----------------------------------------------------------------------------------------

// calculate SAD function
// dx = move right image by dx pixel (dx can be >=0 or <=0)
static int calculateSAD(uint16 * leftImg, uint16 * rightImg, int width, int height,
                        int startX, int startY, int endX, int endY, int dx) {
    int SAD = 0;
    for(int i = startY; i <= endY; i++) {
        for(int j = startX; j <= endX; j++) {
            // get column for right image for calculate
            // note that out of boundary case, here we just skip those regions
            int col = j + dx;
            if(col < 0 || col >= width) continue;
            SAD += abs(leftImg[i*width + j] - rightImg[i*width + col]);
        }
    }
    return SAD;
}
//******************************************************************************************

// do quadratic function fitting and return a,b to compute for PD
// use three minimal samples to do a quadratic function fitting: y = a*x*x + b*x + c
static double * quadfit(int* minThreeIndex, int* minThreeSAD) {
    // result = {a, b}
    double * result = new double[2];
    // minThreeIndex = {x1, x2, x3}, minThreeSAD = {y1, y2, y3}
    double dx1 = minThreeIndex[1] - minThreeIndex[0];
    double dy1 = minThreeSAD[1] - minThreeSAD[0];
    double dx2 = minThreeIndex[2] - minThreeIndex[1];
    double dy2 = minThreeSAD[2] - minThreeSAD[1];
    double sx1 = minThreeIndex[1] * minThreeIndex[1] - minThreeIndex[0] * minThreeIndex[0];
    double sx2 = minThreeIndex[2] * minThreeIndex[2] - minThreeIndex[1] * minThreeIndex[1];

    result[0] = (dx1 * dy2 - dx2 * dy1) / (dx1 * sx2 - dx2 * sx1);
    result[1] = (dy1 - result[0] * sx1) / dx1;

    return result;
}
//******************************************************************************************

int main(int argc, char* argv[]) {
    // STEP<1>: read image into 1-D array(s)
    FILE* file;
    int width;
    int height;
    int bytesPerPixel = 1; // left and right are grey scale image
    /*
    cout << "argc = " << argc << endl;
    for(int i = 0; i < argc; i++) {
        cout << argv[i] << endl;
    }
    */
	// Check for proper syntax	if (argc < 5){		cout << "Syntax Error - Incorrect Parameter Usage:" << endl;
		cout << "argv[1] = width of image        argv[2] = height of image" << endl;		cout << "argv[3] = argleftImageName.raw  argv[4] = rightImgName.raw " << endl;		return 0;	}
	// get image width and height
	width = atoi(argv[1]);
	height = atoi(argv[2]);	// Allocate image data array
	// note that greyscale image here has each pixel of 16 bit	uint16 * leftImg = new uint16[width * height];
	cout << "Allocate memory for left Done! " << endl;
	uint16 * rightImg = new uint16[width * height];
	cout << "Allocate memory for right Done! " << endl;	// Read left image	if (!(file=fopen(argv[3],"rb"))) {		cout << "Cannot open file: " << argv[3] <<endl;		exit(1);	}	fread(leftImg, sizeof(uint16), width*height*bytesPerPixel, file);
	cout << "Sucess Open file: " << argv[3] << endl;
	// Read right image
	if (!(file=fopen(argv[4],"rb"))) {		cout << "Cannot open file: " << argv[4] <<endl;		exit(1);	}	fread(rightImg, sizeof(uint16), width*height*bytesPerPixel, file);
	cout << "Sucess Open file: " << argv[4] << endl;	fclose(file);
	// check if we read correctly
	/*
	while(true) {
        int i, j;
        cout << "type in the location u wanna look for" << endl;
        cin >> i;
        cin >> j;
        if(i < 0 || i >= height || j < 0 || j >= width) break;
        printf("i = %d, j = %d, leftImg(i,j) = %d \n", i, j, leftImg[i*width + j]);
        printf("i = %d, j = %d, rightImg(i,j) = %d \n", i, j, rightImg[i*width + j]);
	}
	*/

	// STEP<2>: calculate SAD - pixel move curve
	// get area u wanna calculate PD
	int startX, startY, endX, endY;
	cout << "Type In the area u want to calculate PD, format: startX startY endX endY " << endl;
	cin >> startX;
	cin >> startY;
	cin >> endX;
	cin >> endY;
	printf("The area (%d, %d) -> (%d, %d) is used for calculating PD \n", startX, startY, endX, endY);
    //cout << calculateSAD(leftImg, rightImg, width, height, startX, startY, endX, endY, 0);
    // record minimal 3 samples -> minThreeSAD(1) < minThreeSAD(2) < minThreeSAD(3)
    int * minThreeSAD = new int[3];
    int * minThreeIndex = new int[3];
    for(int i = 0; i < 3; i++) {
        minThreeSAD[i] = INT_MAX;
        minThreeIndex[i] = 0;
    }
    // record each SAD - move for debug purpose
    int * SADlist = new int[max_move - min_move + 1];
    for(int mv = min_move; mv <= max_move; mv++) {
        int SAD = calculateSAD(leftImg, rightImg, width, height, startX, startY, endX, endY, mv);
        SADlist[mv - min_move] = SAD;
        //cout << SADlist[mv - min_move] << endl;
        // update minimal three samples
        if(SAD < minThreeSAD[0]) {
            minThreeSAD[2] = minThreeSAD[1];
            minThreeIndex[2] = minThreeIndex[1];
            minThreeSAD[1] = minThreeSAD[0];
            minThreeIndex[1] = minThreeIndex[0];
            minThreeSAD[0] = SAD;
            minThreeIndex[0] = mv;
        }
        else if(SAD < minThreeSAD[1]) {
            minThreeSAD[2] = minThreeSAD[1];
            minThreeIndex[2] = minThreeIndex[1];
            minThreeSAD[1] = SAD;
            minThreeIndex[1] = mv;
        }
        else if(SAD < minThreeSAD[2]) {
            minThreeSAD[2] = SAD;
            minThreeIndex[2] = mv;
        }
    }
    /*
    for(int i = 0; i < 3; i++) {
        printf("minThreeIndex[%d] = %d, minThreeSAD[%d] = %d \n", i, minThreeIndex[i], i, minThreeSAD[i]);
    }
    */

    // STEP<3>: calculate PD
    double PD = 0;
    if(minThreeIndex[0] == min_move || minThreeIndex[0] == max_move) {
        PD = (double)minThreeIndex[0];
    }
    else {
        double * param = quadfit(minThreeIndex, minThreeSAD);
        PD = -1 * param[1] / (2 * param[0]);
    }
    printf("PD = %f (pixel) \n", PD);

}
//********************************************************************************************


