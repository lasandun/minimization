// This file contains the host code of the openCL supported minimization
#include <stdio.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdlib.h>
#include <limits.h>       //For PATH_MAX

// import OpenCL headers assuming OS is a linux version or MAC
#ifdef __APPLE__
    #include<OpenCL/opencl.h>
#else
    #include<CL/cl.h>
#endif

#define MAX_SOURCE_SIZE (0x100000) // maximum size allowed for the kernel text

// status of the program
#define SUCCESSFULLY_FINISHED        0
#define KERNEL_BUILD_FALURE         -1
#define RUNTIME_ERROR               -2
#define KERNEL_FILE_NOT_FOUND_ERROR -3

// these are the available minimization methods
enum methods{
      golden_section,
      newton_raphson,
      bisection,
      brent
};

// minimize the given function and set results x_minimum and f_minimum
void opencl_minimize(int n, float* start_point, float* expected_point, float* end_point, enum methods method,
                    char *f, char *fd, char *fdd,
                    float *x_minimum, float *f_minimum,
                    int do_brent_bracketing,
                    int max_iterations, float epsilon, float golden, float brent_sqrt_epsilon,
                    char *path_to_kernel,
                    int *status) {
    char* source_str;
    size_t source_size;
    int i = 0;
    //set the status as runtime. If no errors occured, status will be set as successful
    // at the end of the calculation
    *status = RUNTIME_ERROR;

    // read the corresponding kernel
    FILE* fp;
    // bisection, golden section and newton-rampson kernel codes are in one file
    if(method != brent) {
        // append the file name to the absolute path
        sprintf(path_to_kernel, "%s%s", path_to_kernel, "/unidimensional_kernel.cl");
        fp = fopen(path_to_kernel, "r");
    }
    // brent method's kernel is in a seperate file
    else {
        // append the file name to the absolute path
        sprintf(path_to_kernel, "%s%s", path_to_kernel, "/unidimensional_brent_kernel.cl");
        fp = fopen(path_to_kernel, "r");
    }

    // if the kernel file doesn't exist, stop the execution
    if(fp == 0) {
        printf("kernel file not found\n");
        *status = KERNEL_FILE_NOT_FOUND_ERROR;
        exit(0);
    }
    
    char *temp_source;
    // allocate memory for kenel code
    temp_source = (char*) malloc(sizeof(char) * MAX_SOURCE_SIZE);
    source_str  = (char*) malloc(sizeof(char) * MAX_SOURCE_SIZE);

    temp_source[0] = '\0';  // make temp_source a null string
    char line[100];
    // read the text of the kernel into temp_source
    while(!feof(fp)) {
        if (fgets(line, 100, fp)) {
            sprintf(temp_source, "%s%s",temp_source, line);
        }
    }

    // if the minimization method isn't newton rampson method, derivatives
    // aren't required
    if(method != newton_raphson) {
        fd  = "1";
        fdd = "1";
    }
    // create the complete kernel code appending,
    // f()   - minimizing function
    // fd()  - first derivative
    // fdd() - second deivative
    sprintf(source_str, "float f(float x){return (%s);}\n"
    "float fd(float x){return (%s);}\n"
    "float fdd(float x){return (%s);}\n"
    "%s", f, fd, fdd, temp_source);

    // printf("\nfunction----------------------------\n%s\n--------------------------\n", source_str);
    source_size = strlen(source_str);
    fclose(fp);
    free(temp_source);

    cl_platform_id platform_id = NULL;
    cl_device_id device_id     = NULL;   
    cl_uint ret_num_devices;
    cl_uint ret_num_platforms;
    cl_int ret;
    ret = clGetPlatformIDs(1, &platform_id, &ret_num_platforms);
    // for minimization, the computing device is set as the CPU
    ret = clGetDeviceIDs( platform_id, CL_DEVICE_TYPE_CPU, 1, &device_id, &ret_num_devices);

    // create kernel
    cl_context context = clCreateContext( NULL, 1, &device_id, NULL, NULL, &ret);
    // create command queue
    cl_command_queue command_queue = clCreateCommandQueue(context, device_id, 0, &ret);    

    // create memory buffers to share memory with kernel program 
    cl_mem max_iter_obj     = clCreateBuffer(context, CL_MEM_READ_ONLY,  sizeof(int)       , NULL, &ret);
    cl_mem epsilon_obj      = clCreateBuffer(context, CL_MEM_READ_ONLY,  sizeof(float)     , NULL, &ret);
    cl_mem golden_obj       = clCreateBuffer(context, CL_MEM_READ_ONLY,  sizeof(float)     , NULL, &ret);
    cl_mem start_obj        = clCreateBuffer(context, CL_MEM_READ_ONLY,  sizeof(float) * n , NULL, &ret);
    cl_mem end_obj          = clCreateBuffer(context, CL_MEM_READ_ONLY,  sizeof(float) * n , NULL, &ret);
    cl_mem expected_obj     = clCreateBuffer(context, CL_MEM_READ_ONLY,  sizeof(float) * n , NULL, &ret);
    cl_mem n_obj            = clCreateBuffer(context, CL_MEM_READ_ONLY,  sizeof(int)       , NULL, &ret);
    cl_mem x_minimum_obj    = clCreateBuffer(context, CL_MEM_READ_WRITE, sizeof(float) * n , NULL, &ret);
    cl_mem f_minimum_obj    = clCreateBuffer(context, CL_MEM_READ_WRITE, sizeof(float) * n , NULL, &ret);
    cl_mem method_obj       = clCreateBuffer(context, CL_MEM_READ_ONLY,  sizeof(int)       , NULL, &ret);
    // for brent method only
    cl_mem bracketing_obj   = clCreateBuffer(context, CL_MEM_READ_ONLY,  sizeof(int)       , NULL, &ret);
    cl_mem sqrt_epsilon_obj = clCreateBuffer(context, CL_MEM_READ_ONLY,  sizeof(float)     , NULL, &ret);

    // writes the input values into the allocated memory buffers
    // the start points and end points are required all methods except the newton-rampson method
    if(method != newton_raphson) {
        ret = clEnqueueWriteBuffer(command_queue, start_obj, CL_TRUE, 0, sizeof(float) * n, start_point, 0, NULL, NULL);
        ret = clEnqueueWriteBuffer(command_queue, end_obj  , CL_TRUE, 0, sizeof(float) * n, end_point  , 0, NULL, NULL);
    }
    ret = clEnqueueWriteBuffer(command_queue, max_iter_obj, CL_TRUE, 0, sizeof(int)      , &max_iterations, 0, NULL, NULL);
    ret = clEnqueueWriteBuffer(command_queue, epsilon_obj , CL_TRUE, 0, sizeof(float)    , &epsilon       , 0, NULL, NULL);
    ret = clEnqueueWriteBuffer(command_queue, golden_obj  , CL_TRUE, 0, sizeof(float)    , &golden        , 0, NULL, NULL);
    ret = clEnqueueWriteBuffer(command_queue, expected_obj, CL_TRUE, 0, sizeof(float) * n, expected_point , 0, NULL, NULL);
    ret = clEnqueueWriteBuffer(command_queue, n_obj       , CL_TRUE, 0, sizeof(int)      , &n             , 0, NULL, NULL);
    ret = clEnqueueWriteBuffer(command_queue, method_obj  , CL_TRUE, 0, sizeof(int)      , &method        , 0, NULL, NULL);
    // do_brent_bracketing is required only for brent method
    if(method == brent) {
        ret = clEnqueueWriteBuffer(command_queue, bracketing_obj  , CL_TRUE, 0, sizeof(int)  , &do_brent_bracketing, 0, NULL, NULL);
        ret = clEnqueueWriteBuffer(command_queue, sqrt_epsilon_obj, CL_TRUE, 0, sizeof(float), &brent_sqrt_epsilon , 0, NULL, NULL);
    }

    // create kernel program
    cl_program program = clCreateProgramWithSource(context, 1, (const char **)&source_str, (const size_t *)&source_size, &ret);
    // build the kernel program. Still the code isn't being executed
    // memory buffers haven't involved. Any error at this stage MAY be a syntax error of kernel code
    ret = clBuildProgram(program, 1, &device_id, NULL, NULL, NULL);
    // this gives error message only if the kernel code includes any syntax error
    if(ret == CL_BUILD_PROGRAM_FAILURE) {
      printf("\nerror while building kernel: %d\n", ret);
      *status = KERNEL_BUILD_FALURE;
    }
    // create the kernel calling the kernel function 'minimize'
    cl_kernel kernel = clCreateKernel(program, "minimize", &ret);

    // set arguments of kernel function
    ret = clSetKernelArg(kernel, 0 , sizeof(cl_mem) * n, (void *)&start_obj);    
    ret = clSetKernelArg(kernel, 1 , sizeof(cl_mem) * n, (void *)&end_obj);    
    ret = clSetKernelArg(kernel, 2 , sizeof(cl_mem) * n, (void *)&expected_obj);    
    ret = clSetKernelArg(kernel, 3 , sizeof(cl_mem)    , (void *)&n_obj);
    ret = clSetKernelArg(kernel, 4 , sizeof(cl_mem) * n, (void *)&x_minimum_obj);
    ret = clSetKernelArg(kernel, 5 , sizeof(cl_mem) * n, (void *)&f_minimum_obj);
    ret = clSetKernelArg(kernel, 6 , sizeof(cl_mem)    , (void *)&method_obj);
    ret = clSetKernelArg(kernel, 7 , sizeof(cl_mem)    , (void *)&bracketing_obj);
    ret = clSetKernelArg(kernel, 8 , sizeof(cl_mem)    , (void *)&max_iter_obj);
    ret = clSetKernelArg(kernel, 9 , sizeof(cl_mem)    , (void *)&epsilon_obj);
    ret = clSetKernelArg(kernel, 10, sizeof(cl_mem)    , (void *)&golden_obj);
    ret = clSetKernelArg(kernel, 11, sizeof(cl_mem)    , (void *)&sqrt_epsilon_obj);

    size_t global_item_size = n;
    // enqueue the jobs and let them to be solved by kernel program
    ret = clEnqueueNDRangeKernel(command_queue, kernel, 1, NULL, &global_item_size, NULL, 0, NULL, NULL);
    
    // retrieve results from the shared memory buffers
    ret = clEnqueueReadBuffer(command_queue, x_minimum_obj, CL_TRUE, 0, n * sizeof(float), x_minimum, 0, NULL, NULL);
    ret = clEnqueueReadBuffer(command_queue, f_minimum_obj, CL_TRUE, 0, n * sizeof(float), f_minimum, 0, NULL, NULL);

    // clear the allocated memory
    ret = clFlush(command_queue);
    ret = clFinish(command_queue);
    ret = clReleaseKernel(kernel);
    ret = clReleaseProgram(program);

    ret = clReleaseMemObject(start_obj);
    ret = clReleaseMemObject(expected_obj);
    ret = clReleaseMemObject(end_obj);
    ret = clReleaseMemObject(n_obj);
    ret = clReleaseMemObject(method_obj);
    ret = clReleaseMemObject(x_minimum_obj);
    ret = clReleaseMemObject(f_minimum_obj);
    ret = clReleaseMemObject(bracketing_obj);
    ret = clReleaseMemObject(max_iter_obj);
    ret = clReleaseMemObject(epsilon_obj);
    ret = clReleaseMemObject(golden_obj);
    ret = clReleaseMemObject(sqrt_epsilon_obj);

    ret = clReleaseCommandQueue(command_queue);
    ret = clReleaseContext(context);
    free(source_str);

    // set status is still 'RUNTIME_ERROR', no error
    // has occured at the execution.
    if(*status == RUNTIME_ERROR) {
        *status = SUCCESSFULLY_FINISHED;
    }

}
