#define epsilon 1e-10
#define max_iteration 1000

void golden_section(float start_point, float upper, float expected, float *x_minimum, float *f_minimum);
void newton_raphson(float start_point, float upper, float expected, float *x_minimum, float *f_minimum);

__kernel void minimize(__global const float *a, __global const float *b, __global const float *expected, __global const int *n,
                       __global float *x_minimum, __global float *f_minimum,  __global const int *method){
 
    // Get the index of the current element to be processed
    int i = get_global_id(0);
 
    // Do the operation
    if(i < n) {
        float x = 0;
        float f = 0;
        int m = *method;
        switch(m) {
            case 0: golden_section(a[i], b[i], expected[i], &x, &f);
                    break;
            case 1: newton_raphson(a[i], b[i], expected[i], &x, &f);
                    break;
        }

        x_minimum[i] = x;
        f_minimum[i] = f;
    }
}

void golden_section(float lower, float upper, float expected, float *x_minimum, float *f_minimum) {
    float ax, bx, cx; 
    float x0, x1, x2, x3;
    float f1, f2;
    float c = (3 - 2.236067) / 2;
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
    while(fabs(x3 - x0) > epsilon && k < max_iteration) {
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
void newton_raphson(float start_point, float upper, float expected, float *x_minimum, float *f_minimum) {
    float x_prev, x, f_prev, f;
    x_prev = start_point;
    x = expected;
    int k=0;
    while(fabs(x - x_prev) > epsilon && k < max_iteration) {
      k += 1;
      x_prev = x;
      x = x - fd(x) / fdd(x);//   (@proc_1d.call(x).quo(@proc_2d.call(x)));
      //f_prev = f(x_prev);
      //f = f(x);
      //x_min,x_max=[x,x_prev].min, [x,x_prev].max
      //f_min,f_max=[f,f_prev].min, [f,f_prev].max 
    }
    //*x_minimum = x;
    //*f_minimum = f(x);
}


