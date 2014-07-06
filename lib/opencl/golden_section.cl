#define epsilon 1e-5
#define max_iteration 100

float find_min(float start_point, float upper);

__kernel void minimize(__global const float *a, __global const float *b, __global const float *n, __global float *results) {
 
    // Get the index of the current element to be processed
    int i = get_global_id(0);
 
    // Do the operation
    if(i <= n) {
        results[i] = find_min(*a, *b);// (f((*a) + (*dx) * i) + f((*a) + (*dx) * (i + 1))) * (*dx) / 2;
    }
}

float find_min(float lower, float upper){
    float ax, bx, cx; 
    float x0, x1, x2, x3;
    float f1, f2;
    float c = (3 - 2.236067) / 2;
    float r = 1 - c;

    ax = lower;
    bx = (upper + lower) / 2.0;//expected[i];
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
      // x_minimum[i] = x1;
      // f_minimum[i] = f1;
      return x1;
    }
    else {
      // x_minimum[i] = x2;
      // f_minimum[i] = f2;
      return x2;
    }

}

