// This is the kenel code for Brent minimizing method.
// This is loaded into memory at runtime and some other functions will be appended such as,
// float f(float x)   - minimizing function
// float fd(float x)  - first derivative (not required in this method)
// float fdd(float x) - second derivative (not required in this method)

#define x_minimum global_data[0]
#define f_minimum global_data[1]
#define f_lower   global_data[2]
#define f_upper   global_data[3]
#define x_lower   global_data[4]
#define x_upper   global_data[5]
#define v         global_data[6]
#define w         global_data[7]
#define d         global_data[8]
#define e         global_data[9]
#define f_v       global_data[10]
#define f_w       global_data[11]
#define w_upper   global_data[12]
#define w_lower   global_data[13]


int brent_bracketing(float *global_data, float golden, float GSL_SQRT_DBL_EPSILON);
int brent_iterate(float *global_data, float golden, float GSL_SQRT_DBL_EPSILON);
void initialize(float lower, float upper, float *global_data, float golden);

// kernel function which is being called by the host program.
__kernel void minimize(__global const float *a, __global const float *b, __global const float *expected, __global const int *n,
                       __global float *x_min, __global float *f_min,   __global const int *method,
                       __global const int *do_brent_bracketing,
                       __global const int *max_iterations, __global const float *epsilon, __global const float *golden,
                       __global const float *GSL_SQRT_DBL_EPSILON) {
 
    // Get the index of the current element to be processed
    int i = get_global_id(0);
 
    // Do the operation only for valid i values
    if(i < *n) {

        // Needs to pass a lot of variables to initialize, brent_bracketing and brent_iterate methods.
        // Therefore all the data is put into one array and calls them using preprocessor derivatives.
        // Check the defined preprocessor derivatives for meaning of each index of 'global_data' array.
        float global_data[14];

        initialize(a[i], b[i], global_data, *golden);

        // bracketing is done only if the exptected value ins't given
        if(*do_brent_bracketing == 1) {
            brent_bracketing(global_data, *golden, *GSL_SQRT_DBL_EPSILON);
        }
        else {
            // expected value is given
            x_minimum = expected[i];
            f_minimum = f(expected[i]);
        }

        int k = 0;
        // do brent_iterate until the max_iterations reached or the required 
        // accuracy is taken
        while(k < *max_iterations && fabs(x_lower - x_upper) > *epsilon) {
          k += 1;
          brent_iterate(global_data, *golden, *GSL_SQRT_DBL_EPSILON);
        } 

        // set the results
        x_min[i] = global_data[0];
        f_min[i] = global_data[1];
    }
}

// brent bracketing function
int brent_bracketing(float *global_data, float golden, float GSL_SQRT_DBL_EPSILON) {
  float eval_max, f_left, f_right, nb_eval, f_center, x_center, x_left, x_right;
  eval_max = 10;
  f_left   = f_lower;
  f_right  = f_upper;
  x_left   = x_lower;
  x_right  = x_upper;
   
  nb_eval = 0;
  if(f_right >= f_left) {
    x_center = (x_right - x_left) * golden + x_left;
    nb_eval+=1;
    f_center=f(x_center);
  }
  else {
    x_center = x_right ;
    f_center = f_right ;
    x_right  = (x_center - x_left)/(golden) + x_left;
    nb_eval += 1;
    f_right  = f(x_right);
  }

  do { 
    if (f_center < f_left ) {
      if (f_center < f_right) {
        x_lower   = x_left;
        x_upper   = x_right;
        x_minimum = x_center;
        f_lower   = f_left;
        f_upper   = f_right;
        f_minimum = f_center;
        return 1;
      }
      else if(f_center > f_right) {
        x_left   = x_center;
        f_left   = f_center;
        x_center = x_right;
        f_center = f_right;
        x_right  = (x_center - x_left)/(golden) + x_left;
        nb_eval +=1;
        f_right  = f(x_right);
      }
      else { // f_center == f_right
        x_right  = x_center;
        f_right  = f_center;
        x_center = (x_right - x_left)/(golden) + x_left;
        nb_eval +=1;
        f_center = f(x_center);
      }
    }
    else {// f_center >= f_left
      x_right  = x_center;
      f_right  = f_center;
      x_center = (x_right - x_left) * golden + x_left;
      nb_eval +=1;
      f_center =f(x_center);
    }
  } while((nb_eval < eval_max) && ((x_right - x_left) > GSL_SQRT_DBL_EPSILON * ( (x_right + x_left) * 0.5 ) + GSL_SQRT_DBL_EPSILON));
  x_lower   = x_left;
  x_upper   = x_right;
  x_minimum = x_center;
  f_lower   = f_left;
  f_upper   = f_right;
  f_minimum = f_center;
  return 0;
}

// initialize the inputs
void initialize(float lower, float upper, float *global_data, float golden) {
  float v_tmp = lower + golden * (upper - lower);
  float w_tmp = v_tmp;

  x_minimum = v_tmp ;
  f_minimum = f(v_tmp) ;
  x_lower = lower;
  x_upper = upper;
  f_lower = f(lower) ;
  f_upper = f(lower) ;

  v = v_tmp;
  w = w_tmp;

  d = 0;
  e = 0;
  f_v = f(v_tmp);
  f_w = f_v;
}

// iterate Brent method from one step
int brent_iterate(float *global_data, float golden, float GSL_SQRT_DBL_EPSILON) {
  float x_left, x_right;
  float d_tmp, e_tmp, z_tmp, v_tmp, w_tmp, f_v_tmp, f_w_tmp, f_z_tmp;

  x_left = x_lower;
  x_right = x_upper;

  float u;

  z_tmp = x_minimum;
  d_tmp = e;
  e_tmp = d;
  v_tmp = v;
  w_tmp = w;
  f_v_tmp = f_v;
  f_w_tmp = f_w;
  f_z_tmp = f_minimum;

  w_lower = (z_tmp - x_left);
  w_upper = (x_right - z_tmp);

  float tolerance =  GSL_SQRT_DBL_EPSILON * fabs(z_tmp);

  float midpoint = 0.5 * (x_left + x_right);
  float _p = 0, q = 0, r = 0;
  if (fabs(e_tmp) > tolerance) {

    // fit parabola

    r = (z_tmp - w_tmp) * (f_z_tmp - f_v_tmp);
    q = (z_tmp - v_tmp) * (f_z_tmp - f_w_tmp);
    _p = (z_tmp - v_tmp) * q - (z_tmp - w_tmp) * r;
    q = 2 * (q - r);

    if (q > 0)
      _p = -_p;
    else
      q = -q;

    r = e_tmp;
    e_tmp = d_tmp;
  }

  if (fabs(_p) < fabs(0.5 * q * r) && _p < q * w_lower && _p < q * w_upper) {
    float t2 = 2 * tolerance ;

    d_tmp = _p / q;
    u = z_tmp + d_tmp;

    if ((u - x_left) < t2 || (x_right - u) < t2)
      d = (z_tmp < midpoint) ? tolerance : -tolerance ;
  }
  else {

    e_tmp = (z_tmp < midpoint) ? x_right - z_tmp : -(z_tmp - x_left) ;
    d_tmp = golden * e_tmp;
  }

  if ( fabs(d_tmp) >= tolerance)
    u = z_tmp + d_tmp;
  else
    u = z_tmp + ((d_tmp > 0) ? tolerance : -tolerance) ;

  e = e_tmp;
  d = d_tmp;

  float f_u = f(u);

  if (f_u <= f_z_tmp) {
    if (u < z_tmp) {
      x_upper = z_tmp;
      f_upper = f_z_tmp;
    }
    else {
      x_lower = z_tmp;
      f_lower = f_z_tmp;
    }
    v = w_tmp;
    f_v_tmp = f_w_tmp;
    w = z_tmp;
    f_w = f_z_tmp;
    x_minimum = u;
    f_minimum = f_u;
    return true;
  }
  else {
    if (u < z_tmp) {
      x_lower = u;
      f_lower = f_u;
      return true;
    }
    else {
      x_upper = u;
      f_upper = f_u;
      return true;
    }

    if (f_u <= f_w_tmp || w_tmp == z_tmp) {
      v = w_tmp;
      f_v = f_w_tmp;
      w = u;
      f_w = f_u;
      return true;
    }
    else if( f_u <= f_v_tmp || v_tmp == z_tmp || v_tmp == w_tmp) {
      v = u;
      f_v = f_u;
      return true;
    }
  }
  return false;
}

