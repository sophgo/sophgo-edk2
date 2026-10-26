RM = rm -f
OBJS = pack.o
TARGET = pack

all: $(TARGET)

$(TARGET): $(OBJS)
	$(CC) $(CFLAGS) -o $@ $(OBJS)
	
clean:
	$(RM) $(OBJS) $(TARGET)
