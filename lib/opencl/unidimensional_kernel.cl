#define epsilon 1e-5
#define max_iteration 10e10

void golden_section(float lower, float upper, float expected, float *x_minimum, float *f_minimum);
void newton_raphson(float lower, float upper, float expected, float *x_minimum, float *f_minimum);
void bisection(float lower, float upper, float expected, float *x_minimum, float *f_minimum);

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
            case 2: bisection(a[i], b[i], expected[i], &x, &f);
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

void newton_raphson(float lower, float upper, float expected, float *x_minimum, float *f_minimum) {
    float x_prev, x1, f_prev, f1;
    x_prev = expected;
    x1     = expected;
    int k  = 0;
    while(k==0 || (fabs(x1 - x_prev) > epsilon && k < max_iteration)) {
        k     += 1;
        x_prev = x1;
        x1     = x1 - fd(x1) / fdd(x1);
        f_prev = f(x_prev);
        f1     = f(x1);
    }
    *x_minimum = x1;
    *f_minimum = f1;
}

void bisection(float lower, float upper, float expected, float *x_minimum, float *f_minimum) {
    float ax, cx, bx, fa, fb, fc;

    ax = lower;
    cx = upper;
    int k = 0;
    while(fabs(ax - cx) > epsilon && k < max_iteration) {
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


float f_lower,f_upper,x_minimum;
float golden = 0.3819660;       // golden = (3 - sqrt(5))/2
float x_minimum, f_minimum;
float GSL_SQRT_DBL_EPSILON = 1e-4;

int brent_bracketing() {
  float eval_max,f_left,f_right,nb_eval,f_center,x_center,x_left,x_right,x_lower,x_upper;
  eval_max=10;
  f_left = f_lower;
  f_right = f_upper;
  x_left = x_lower;
  x_right= x_upper;
   
  nb_eval=0;
  if(f_right >= f_left) {
    x_center = (x_right - x_left) * golden + x_left;
    nb_eval+=1;
    f_center=f(x_center);
  }
  else {
    x_center = x_right ;
    f_center = f_right ;
    x_right = (x_center - x_left)/(golden) + x_left;
    nb_eval+=1;
    f_right=f(x_right);
  }

  do { 
    if (f_center < f_left ) {
      if (f_center < f_right) {
        x_lower = x_left;
        x_upper = x_right;
        x_minimum = x_center;
        f_lower = f_left;
        f_upper = f_right;
        f_minimum = f_center;
        return 1;
      }
      else if(f_center > f_right) {
        x_left = x_center;
        f_left = f_center;
        x_center = x_right;
        f_center = f_right;
        x_right = (x_center - x_left)/(golden) + x_left;
        nb_eval+=1;
        f_right=f(x_right);
      }
      else { // f_center == f_right */
        x_right = x_center;
        f_right = f_center;
        x_center = (x_right - x_left)/(golden) + x_left;
        nb_eval+=1;
        f_center=f(x_center);
      }
    }
    else {// f_center >= f_left */
      x_right = x_center;
      f_right = f_center;
      x_center = (x_right - x_left) * golden + x_left;
      nb_eval+=1;
      f_center=f(x_center);
    }
  } while((nb_eval < eval_max) && ((x_right - x_left) > GSL_SQRT_DBL_EPSILON * ( (x_right + x_left) * 0.5 ) + GSL_SQRT_DBL_EPSILON));
  x_lower = x_left;
  x_upper = x_right;
  x_minimum = x_center;
  f_lower = f_left;
  f_upper = f_right;
  f_minimum = f_center;
  return 0;
}

void brent(float lower, float upper, float expected, float *x_minimum, float *f_minimum) {

}
