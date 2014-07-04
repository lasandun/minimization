__kernel void golden(__global const float *n, __global const float *lower, __global const float *expected, 
                     __global const float *upper, __global const float *epsilon, __global const float *max_iterations,
                     __global const float *c, __global const float *r,
                     __global float *x_minimum, __global float *f_minimum, __global int *successful) {
 
    // Get the index of the current element to be processed
    int i = get_global_id(0);
 
    // Do the operation
    if(i > n) return;
    *successful[i] = 1; // succesful

    double ax, bx, cx; 
    double x0, x1, x2, x3;
    double f1, f2;

    // read inputs of i th job
    ax = lower[i];
    bx = expected[i];
    cx = upper[i];

    x0 = ax;
    x3 = cx;
    if (fabs(cx - bx) > fabs(bx - ax)) {
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
      k += 1;
    }
    // set results of i th job
    if(f1 < f2) {
      x_minimum[i] = x1;
      f_minimum[i] = f1;
      return;
    }
    else {
      x_minimum[i] = x2;
      f_minimum[i] = f2;
      return;
    }
}

