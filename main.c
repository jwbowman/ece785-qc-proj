
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>

#define N 1000
#define STEPS 16
#define EPS 0x33D6BF95

void mandel_inner_loop(float* x,float* y,float* z, float* m, int i, float *out, int eps);

float m[N], x[N], y[N], z[N], vx[N], vy[N], vz[N], xnew[N], ynew[N], znew[N];
float out[12];

void  diff(struct timespec * difference, struct timespec start, struct timespec end)
{
  if ((end.tv_nsec-start.tv_nsec)<0) {
    difference->tv_sec = end.tv_sec-start.tv_sec-1;
    difference->tv_nsec = 1000000000+end.tv_nsec-start.tv_nsec;
  } else {
    difference->tv_sec = end.tv_sec-start.tv_sec;
    difference->tv_nsec = end.tv_nsec-start.tv_nsec;
  }
}

void init(void) {
  int i;

  for(i=0; i<N; i++) { /* Foreach particle "i" ... */
    x[i] = rand();
    y[i] = rand();
    z[i] = rand();
    vx[i] = rand()/100;
    vy[i] = rand()/100;
    vz[i] = rand()/100;
    m[i] = rand();
  }
}

void enable_runfast()
{
	static const unsigned int x = 0x04086060;
	static const unsigned int y = 0x03000000;
	int r;
	asm volatile (
		"fmrx	%0, fpscr			\n\t"	//r0 = FPSCR
		"and	%0, %0, %1			\n\t"	//r0 = r0 & 0x04086060
		"orr	%0, %0, %2			\n\t"	//r0 = r0 | 0x03000000
		"fmxr	fpscr, %0			\n\t"	//FPSCR = r0
		: "=r"(r)
		: "r"(x), "r"(y)
	);
}


int main (int argc, char * argv[]) {
  volatile int s,i,k;
  volatile float ax, ay, az, dt=0.001;
  struct timespec t1, t2, d;
  init();
  enable_runfast();

  

 for(k=0; k<10;k++) {
  
  clock_gettime(CLOCK_PROCESS_CPUTIME_ID, &t1);
 
  for (s=0; s<STEPS; s++) {
    for(i=0; i<N; i++) { /* Foreach particle "i" ... */
    
      //function written in assembly representing inner loop iterations	
      mandel_inner_loop(x, y, z, m, i, out, EPS);
      
      //compute accumulation on values returned from function
      ax = (out[0]+out[1]+out[2]+out[3]);
      ay = (out[4]+out[5]+out[6]+out[7]);
      az = (out[8]+out[9]+out[10]+out[11]);

      xnew[i] = x[i] + dt*vx[i] + 0.5*dt*dt*ax; /* update position of particle "i" */
      ynew[i] = y[i] + dt*vy[i] + 0.5*dt*dt*ay;
      znew[i] = z[i] + dt*vz[i] + 0.5*dt*dt*az;	
 	
      vx[i] += dt*ax; /* update velocity of particle "i" */
      vy[i] += dt*ay;
      vz[i] += dt*az;

    }
    for(i=0;i<N;i++) { /* copy updated positions back into original arrays */
      x[i] = xnew[i];
      y[i] = ynew[i];
      z[i] = znew[i];
    }
  }
 clock_gettime(CLOCK_PROCESS_CPUTIME_ID, &t2);

 }
 

  diff(&d, t1, t2);
  printf("Execution Time: %ld sec, %ld nsec\n", d.tv_sec, d.tv_nsec);

  //print sum to make sure answer is consistent after changes
  float sum = 0.0f;
  for(i=0; i<N;i++) {
      sum  +=  x[i] +  y[i] + z[i];
  }
  printf("Sum : %f vs 3172936450048.00000\n", sum);

  return 0;
}
