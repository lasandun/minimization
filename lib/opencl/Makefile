all: cl.so

CC=gcc
CL_HEADERS_PATH=
LIBOPENCL_PATH=

cl.so: min_host.o
	$(CC) -shared -o cl.so min_host.o -I $(CL_HEADERS_PATH) -L $(LIBOPENCL_PATH) -lOpenCL

min_host.o: min_host.c
	$(CC) -fpic -c min_host.c

clean:
	rm cl.so min_host.o
