all: cl.so

CC=gcc
CL_HEADERS_PATH=
LIBOPENCL_PATH=


UNAME := $(shell uname)
ifeq ($(UNAME), Linux)
# do something Linux-y
OPENCL_LIBRARY_CALL=-lOpenCL
endif
ifeq ($(UNAME), Solaris)
# do something Solaris-y
OPENCL_LIBRARY_CALL=-framework OpenCL
endif



cl.so: min_host.o
	$(CC) -shared -o cl.so min_host.o -I $(CL_HEADERS_PATH) -L $(LIBOPENCL_PATH) $(OPENCL_LIBRARY_CALL)


min_host.o: min_host.c
	$(CC) -fpic -c min_host.c

clean:
	rm cl.so min_host.o
