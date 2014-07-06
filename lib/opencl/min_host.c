#include <CL/cl.h>
#include <stdio.h>
#include <stdlib.h>
#define MAX_SOURCE_SIZE (0x100000)


float util_integrate(float start_point, float end_point, float n, char* f) {
    char* source_str;
    size_t source_size;
    int i = 0;

    //float dx = (b-a) / (n*1.0);
    float *results = (float*) malloc(n * sizeof(float));

    FILE* fp = fopen("./golden_section.cl", "r");
    if(fp == 0){
        printf("kernel file not found");
        free(results);
        exit(0);
    }

    char *temp_source;
    temp_source = (char*) malloc(sizeof(char) * MAX_SOURCE_SIZE);
    source_str  = (char*) malloc(sizeof(char) * MAX_SOURCE_SIZE);
    fread( temp_source, 1, MAX_SOURCE_SIZE, fp);
    sprintf(source_str, "float f(float x){return (%s);} \n %s", f, temp_source);
    //printf("\nfunction : \n%s \n", source_str);
    source_size = strlen(source_str);
    fclose( fp );
    free(temp_source);

    cl_platform_id platform_id = NULL;
    cl_device_id device_id = NULL;   
    cl_uint ret_num_devices;
    cl_uint ret_num_platforms;
    cl_int ret = clGetPlatformIDs(1, &platform_id, &ret_num_platforms);
    ret = clGetDeviceIDs( platform_id, CL_DEVICE_TYPE_CPU/*CL_DEVICE_TYPE_DEFAULT*/, 1, &device_id, &ret_num_devices);

    // create kernel
    cl_context context = clCreateContext( NULL, 1, &device_id, NULL, NULL, &ret);
    cl_command_queue command_queue = clCreateCommandQueue(context, device_id, 0, &ret);    

    cl_mem start_obj  = clCreateBuffer(context, CL_MEM_READ_ONLY, sizeof(float), NULL, &ret);
    cl_mem end_obj    = clCreateBuffer(context, CL_MEM_READ_ONLY, sizeof(float), NULL, &ret);
    cl_mem n_obj  = clCreateBuffer(context, CL_MEM_READ_ONLY, sizeof(float), NULL, &ret);
    cl_mem result_obj = clCreateBuffer(context, CL_MEM_READ_WRITE, n * sizeof(float), NULL, &ret);

    ret = clEnqueueWriteBuffer(command_queue, start_obj, CL_TRUE, 0, sizeof(int), &start_point, 0, NULL, NULL);
    ret = clEnqueueWriteBuffer(command_queue, end_obj  , CL_TRUE, 0, sizeof(int), &end_point  , 0, NULL, NULL);
    ret = clEnqueueWriteBuffer(command_queue, n_obj, CL_TRUE, 0, sizeof(int), &n, 0, NULL, NULL);

    cl_program program = clCreateProgramWithSource(context, 1, (const char **)&source_str, (const size_t *)&source_size, &ret);
    ret = clBuildProgram(program, 1, &device_id, NULL, NULL, NULL);

    cl_kernel kernel = clCreateKernel(program, "minimize", &ret);

    // set arguments of kernel
    ret = clSetKernelArg(kernel, 0, sizeof(cl_mem), (void *)&start_obj);    
    ret = clSetKernelArg(kernel, 1, sizeof(cl_mem), (void *)&end_obj);    
    ret = clSetKernelArg(kernel, 2, sizeof(cl_mem), (void *)&n_obj);
    ret = clSetKernelArg(kernel, 3, sizeof(cl_mem), (void *)&result_obj);

    // execute kernel
    size_t global_item_size = n;
    //size_t local_item_size = n;
    ret = clEnqueueNDRangeKernel(command_queue, kernel, 1, NULL, &global_item_size, NULL/*&local_item_size*/, 0, NULL, NULL);
    
    // retrieve values from array
    ret = clEnqueueReadBuffer(command_queue, result_obj, CL_TRUE, 0, n * sizeof(int), results, 0, NULL, NULL);
    
    float res = 0;
    for(i=0; i < n; ++i) {
        res = results[i];
    }


    ret = clFlush(command_queue);
    ret = clFinish(command_queue);
    ret = clReleaseKernel(kernel);
    ret = clReleaseProgram(program);
    ret = clReleaseMemObject(start_obj);
    ret = clReleaseMemObject(end_obj);
    ret = clReleaseMemObject(n_obj);
    ret = clReleaseMemObject(result_obj);
    ret = clReleaseCommandQueue(command_queue);
    ret = clReleaseContext(context);
    free(results);
    free(source_str);

    return res;
}

int main() {
    printf("%f \n", util_integrate(-5, 5, 100, "(x+1)*(x+1)"));
    return 0;
}
