#define epsilon 1e-5
#define max_iteration 10e10


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
