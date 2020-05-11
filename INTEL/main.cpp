/*TO USE ONLY WITH 32bit BMP FILES WITHOUT COLOR SCHEME ONLY*/

#include <iostream>
#include <fstream>
#include <GL/glut.h>
#include "f.hpp"

#define HEADER_SIZE 54

uint8_t* inPixelsBuffer = nullptr;
uint8_t* outPixelsBuffer = nullptr;
uint8_t headerBuffer[HEADER_SIZE];
uint32_t x_size, y_size;

void display()
{
   glViewport((GLsizei) 0, (GLsizei) 0, (GLsizei) 0, (GLsizei) 0);
   glClear(GL_COLOR_BUFFER_BIT);
   glPixelStorei(GL_UNPACK_ALIGNMENT, 1);

   // Position first image starting at 0, 0
   glRasterPos2f(0, 0);
   // Get the width and height of image as first two params
   glDrawPixels(x_size, y_size, GL_RGBA, GL_UNSIGNED_BYTE, inPixelsBuffer);

   glViewport((GLsizei) 0, (GLsizei) 0, (GLsizei) x_size * 2 + 5, (GLsizei) 0);
   // Position second image starting after the width of the first image
   glRasterPos2f(0, 0);
   // get width and height of second image as first two params
   glDrawPixels(x_size, y_size, GL_RGBA, GL_UNSIGNED_BYTE, outPixelsBuffer);

   glutSwapBuffers();
}

int main(int argc, char *argv[])
{
	if (2 > argc)
	{
		printf("Not enought arguments. Please write in a path to your 32bit BMP img.\n");
		return 0;
	}

	std::ifstream in_img;
	std::string img_path = argv[1];


    in_img.open(img_path, std::ios::binary);
    if(!in_img.is_open()){
        std::cout << "I can't open file " << img_path << "! Maybe you typed in a wrong path?" << std::endl;
    }

    std::cout << "Opening " << img_path << " was successful!\n" << std::endl;

    in_img.read((char*)headerBuffer, HEADER_SIZE);

    uint32_t imgSize = *(uint32_t*)(headerBuffer + 2);
    uint32_t offset = *(uint32_t*)(headerBuffer + 10);
    x_size = *(uint32_t*)(headerBuffer + 18);
    y_size = *(uint32_t*)(headerBuffer + 22);

    std::cout << "Results of loading data:\n"
        << "Size of image = " << imgSize
        << "\nOffset = " << offset
        << "\nx_size = " << x_size
        << "\ny_size = " << y_size << std::endl;

    inPixelsBuffer = new uint8_t[imgSize - offset];
    in_img.read((char*)inPixelsBuffer, imgSize - offset);

    outPixelsBuffer = new uint8_t[imgSize - offset];
    for(int i = 0; i < imgSize - offset; i++){
        outPixelsBuffer[i] = 0xff;
    }

    f(inPixelsBuffer, outPixelsBuffer, x_size, y_size);

    std::ofstream out_img("output.bmp");
    out_img.write((char*)headerBuffer, HEADER_SIZE);
    out_img.write((char*)outPixelsBuffer, imgSize - offset);
    out_img.close();
    in_img.close();
    std::cout << "\nThe result has been saved to output.bmp!" << std::endl;

    glutInit(&argc, argv);
    glutInitDisplayMode(GLUT_SINGLE);
    glutInitWindowSize(x_size * 2, y_size);
    glutCreateWindow("Sorter Results");
    glutDisplayFunc(display);
    glutMainLoop();

	delete [] inPixelsBuffer;
	delete [] outPixelsBuffer;

	return 0;
}
