// This is the kenel code for Golden-Section, Bisection and Newton-Rampsom minimizing methods.
// This is loaded into memory at runtime and some other functions will be appended,
// float f(float x)   - minimizing function
// float fd(float x)  - first derivative
// float fdd(float x) - second derivative

void golden_section(float lower, float upper, float expected, float *x_minimum, float *f_minimum, int max_iterations,
                    float epsilon, float golden);
void newton_raphson(float lower, float upper, float expected, float *x_minimum, float *f_minimum, int max_iterations,
                    float epsilon);
void bisection(float lower, float upper, float expected, float *x_minimum, float *f_minimum, int max_iterations,
               float epsilon);

// kernel function which is being called by the host program.
__kernel void minimize(__global const float *a, __global const float *b, __global const float *expected, __global const int *n,
                       __global float *x_minimum, __global float *f_minimum,  __global const int *method,
                       __global const int *do_brent_bracketing,
                         __global const int *max_iterations, __global const float *epsilon, __global const float *golden){
 
    // Get the index of the current element to be processed
    int i = get_global_id(0);
 
    // Do the operation only for valid i values
    if(i < *n) {

        // pass references of f & x to get results. Pointers to pointers
        // aren't allowed in OpenCL kernel
        float x = 0;
        float f = 0;

        int m = *method;

        // calls the corresponding minimizer
        switch(m) {
            case 0: golden_section(a[i], b[i], expected[i], &x, &f, *max_iterations, *epsilon, *golden);
                    break;
            case 1: newton_raphson(a[i], b[i], expected[i], &x, &f, *max_iterations, *epsilon);
                    break;
            case 2: bisection(a[i], b[i], expected[i], &x, &f, *max_iterations, *epsilon);
                    break;
        }

        // set the results at write buffers
        x_minimum[i] = x;
        f_minimum[i] = f;
    }
}

// golden section minimizer
void golden_section(float lower, float upper, float expected, float *x_minimum, float *f_minimum, int max_iterations,
                    float epsilon, float golden) {
    float ax, bx, cx; 
    float x0, x1, x2, x3;
    float f1, f2;
    float c = golden;
    float r = 1 - c;

    ax = lower;
    bx = expected;
    cx = upper;

    x0 = ax;
    x3 = cx;
    if(fabs(cx - bx) > fabs(bx - ax)) {
        x1 = bx;
        x2 = bx + c*(cx - bx);
    }
    else {
        x2 = bx;
        x1 = bx - c*(bx - ax);
    }
    f1 = f(x1);
    f2 = f(x2);

    int k = 1;
    while(fabs(x3 - x0) > epsilon && k < max_iterations) {
      if(f2 < f1) {
         x0 = x1;
         x1 = x2;
         x2 = r * x1 + c * x3;
         f1 = f2;
         f2 = f(x2);
      }
      else {
         x3 = x2;
         x2 = x1;
         x1 = r * x2 + c * x0;
         f2 = f1;
         f1 = f(x1);
      }
      k++;
    }
    // set results of i th job
    if(f1 < f2) {
        *x_minimum = x1;
        *f_minimum = f1;
    }
    else {
        *x_minimum = x2;
        *f_minimum = f2;
    }
}

// Newton-Rampson minimizer
void newton_raphson(float lower, float upper, float expected, float *x_minimum, float *f_minimum, int max_iterations, float epsilon) {
    float x_prev, x1, f_prev, f1;
    x_prev = expected;
    x1     = expected;
    int k  = 0;
    while(k==0 || (fabs(x1 - x_prev) > epsilon && k < max_iterations)) {
        k     += 1;
        x_prev = x1;
        x1     = x1 - fd(x1) / fdd(x1);
        f_prev = f(x_prev);
        f1     = f(x1);
    }
    *x_minimum = x1;
    *f_minimum = f1;
}

// bisection minimizer
void bisection(float lower, float upper, float expected, float *x_minimum, float *f_minimum, int max_iterations, float epsilon) {
    float ax, cx, bx, fa, fb, fc;

    ax = lower;
    cx = upper;
    int k = 0;
    while(fabs(ax - cx) > epsilon && k < max_iterations) {
        bx = (ax + cx) / 2;
        fa = f(ax);
        fb = f(bx);
        fc = f(cx);
        if (fa < fc) {
            cx = bx;
            fc = fb;
        }
        else {
            ax = bx;
            fa = fb;
        }
        k += 1;
    }

    if (fa < fc) {
        *x_minimum = ax;
        *f_minimum = f(ax);
    }
    else {
        *x_minimum = cx;
        *f_minimum = f(cx);
    }
}

