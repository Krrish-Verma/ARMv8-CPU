# ASS01 Example Makefile
#
# This makefile is intended for use with GNU make
# This example is intended to be built with Linaro bare-metal GCC

TARGET=Lab02-3
CC=gcc
LD=gcc

FLAGS=-g -O0

all: $(TARGET)

clean:
	rm -f *.o
	rm -f $(TARGET)

main.o: main.c
# Compile for best debug view (lowest optimization)
	$(CC) $(FLAGS) -c $^  -o $@

test.o: test.S
# Compile for best debug view (lowest optimization)
	$(CC) $(FLAGS) -c $^ -o $@

Lab02_3b.o: Lab02_3b.S
	$(CC) $(FLAGS) -c $< -o $@

Lab02_3d.o: Lab02_3d.S
	$(CC) $(FLAGS) -c $< -o $@

$(TARGET): main.o test.o Lab02_3b.o Lab02_3d.o
	$(LD) $^ -o $@
