CFLAGS = -Wall -pipe $(EXTRA_CFLAGS)

INCLUDES = -I./h

OBJS = md5sys.o header.o

all: clean header

header: $(OBJS)
	$(CC) $(CFLAGS) $(INCLUDES) -o $@ $? $(LIBS)

%.o: %.c
	echo 'CC $@'
	$(CC) -Wall $(INCLUDES) -c -o $@ $< 

clean:
	rm -rf *.o header
