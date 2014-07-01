#include <CL/cl.h>
#include <stdio.h>
#include <stdlib.h>
#define MAX_SOURCE_SIZE (0x100000)

cl_int ret;
cl_platform_id platform_id     = NULL;
cl_device_id device_id         = NULL;   
cl_context context             = NULL;
cl_command_queue command_queue = NULL;
cl_program program             = NULL;
cl_kernel kernel               = NULL;

cl_uint ret_num_platforms = 0;
cl_uint ret_num_devices   = 0;

size_t source_size = 0;
char* source_str   = NULL;
size_t global_item_size;

// load the kernel file into memory
void loadKernel(char* filePath) {
    FILE* fp = fopen(filePath, "r");
    if(fp == 0) {
        printf("kernel file not found");
        free(results);
        return NULL
    }
    source_str  = (char*) malloc(sizeof(char) * MAX_SOURCE_SIZE);
    fread(source_str, 1, MAX_SOURCE_SIZE, fp);
    source_size = strlen(source_str);
    fclose(fp);
}

void createContextNCommandQueue() {
    // get the platform
    ret           = clGetPlatformIDs(1, &platform_id, &ret_num_platforms);
    // ask for atleast one device
    ret           = clGetDeviceIDs( platform_id, CL_DEVICE_TYPE_ALL, 1, &device_id, &ret_num_devices);
    // create context
    context       = clCreateContext( NULL, 1, &device_id, NULL, NULL, &ret);
    // create command queue
    command_queue = clCreateCommandQueue(context, device_id, 0, &ret);
}

// create memory objects for kernel and set the values
void createNParseMemObjects() {
    // create  mem objects for both arguments and results of kernel function. Eg:
    //cl_mem argument_obj  = clCreateBuffer(context, CL_MEM_WRITE_ONLY, allocating_mem_size, NULL, &ret);
    //cl_mem result_obj    = clCreateBuffer(context, CL_MEM_READ_ONLY , allocating_mem_size, NULL, &ret);

    // write the argument values to kernel function. Eg:
    //ret = clEnqueueWriteBuffer(command_queue, mem_obj, CL_TRUE, 0, sizeof(data_type), &value, 0, NULL, NULL);
}

void createKernel() {
    // create the program with given source
    program = clCreateProgramWithSource(context, 1, (const char **)&source_str, (const size_t *)&source_size, &ret);
    // build program
    ret     = clBuildProgram(program, 1, &device_id, NULL, NULL, NULL);
    // create kernel from built program
    kernel  = clCreateKernel(program, "vector_add", &ret);
}

void setKernelArguments() {
    //ret = clSetKernelArg(kernel, argument_no, sizeof(cl_mem), (void *)&a_obj);    
}

void executeKernel() {
    //size_t local_item_size = n;
    global_item_size = n;
    ret = clEnqueueNDRangeKernel(command_queue, kernel, 1, NULL, &global_item_size, NULL/*&local_item_size*/, 0, NULL, NULL);
}

void readResults() {
    ret = clEnqueueReadBuffer(command_queue, result_obj, CL_TRUE, 0, n * sizeof(int), results, 0, NULL, NULL);    
}

void clearMemory() {
    ret = clFlush(command_queue);
    ret = clFinish(command_queue);
    ret = clReleaseKernel(kernel);
    ret = clReleaseProgram(program);
    ret = clReleaseMemObject(a_obj);
    ret = clReleaseMemObject(n_obj);
    ret = clReleaseMemObject(dx_obj);
    ret = clReleaseMemObject(result_obj);
    ret = clReleaseCommandQueue(command_queue);
    ret = clReleaseContext(context);
    free(results);
    free(source_str);
}
