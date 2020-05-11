CC = g++
CFLAGS = -m64 -Wall -g
GLUT = -lglut -lGLU -lGL

ASM = nasm
AFLAGS = -f elf64

all:	sorter

main.o:	main.cpp
	$(CC) $(CFLAGS) -c main.cpp -o main.o

f.o:	f.s
	$(ASM) $(AFLAGS) f.s -o f.o

sorter:	main.o f.o
	$(CC) $(CFLAGS) -o sorter main.o f.o $(GLUT)

yeet:
	rm -f *.o
	rm sorter

