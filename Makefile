
PROJ_NAME = project1
CC = gcc
VECTFLAGS = -ftree-vectorize -ffast-math -fsingle-precision-constant -ftree-vectorizer-verbose=1 -mvectorize-with-neon-quad
CFLAGS = -Wall -ggdb -O3  -mcpu=cortex-a8  -mfloat-abi=softfp  -mfpu=neon $(VECTFLAGS) -funroll-loops 
LIBS = -lm -lrt
OBJFILES := $(patsubst %.c,%.o,$(wildcard *.c)) $(patsubst %.s,%.o,$(wildcard *.s))

$(PROJ_NAME): $(OBJFILES) $(ASM_OBJ)
#	echo $(OBJFILES)
	$(CC) -o $(PROJ_NAME) $(OBJFILES) $(ASM_OBJ) $(LIBS)
%.o: %.c
	$(CC) $(CFLAGS) -c -o $@ $<
%.o : %.s
	$(CC) $(CFLAGS) -c $< -o $@
%.lst: %.c
	$(CC) $(CFLAGS) -Wa,-adhln $(LIBS) $< > $@
clean:
	rm -f *.o *.lst $(PROJ_NAME)
