.RECIPEPREFIX := >
CC = gcc
CFLAGS = -g -O0
TARGET = Lab03
OBJECTS = main.o test.o lab03b.o Lab03c.o

.PHONY: all clean

all: $(TARGET)

$(TARGET): $(OBJECTS)
>$(CC) $(OBJECTS) -o $@

main.o: main.c
>$(CC) $(CFLAGS) -c $< -o $@

%.o: %.S
>$(CC) $(CFLAGS) -c $< -o $@

clean:
>rm -f $(OBJECTS) $(TARGET)
