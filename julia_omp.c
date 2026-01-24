#include <stdio.h>
#include <stdlib.h>
#include <omp.h>

#define WIDTH 10000
#define HEIGHT 10000
#define MAX_ITER 5000

void save_dummy(unsigned char *pixels) {
    FILE *f = fopen("/tmp/julia.raw", "wb");
    if (f) {
        fwrite(pixels, 1, WIDTH * HEIGHT * 3, f);
        fclose(f);
    }
}

int main() {
    double xmin = -1, xmax = 1;
    double ymin = -1, ymax = 1;
    double c_real = -0.8, c_imag = 0.156;

    int max_threads = omp_get_max_threads();
    printf("DEBUG_THREADS: %d\n", max_threads);

    unsigned char *pixels = (unsigned char *)malloc(WIDTH * HEIGHT * 3);
    if (!pixels) return 1;

    double start = omp_get_wtime();

    #pragma omp parallel for schedule(runtime)
    for (int line = 0; line < HEIGHT; line++) {
        for (int col = 0; col < WIDTH; col++) {
            double x = xmin + col * (xmax - xmin) / WIDTH;
            double y = ymax - line * (ymax - ymin) / HEIGHT;
            int i = 0;
            
            while (i < MAX_ITER && (x*x + y*y) <= 4.0) {
                double x_tmp = x*x - y*y + c_real;
                y = 2*x*y + c_imag;
                x = x_tmp;
                i++;
            }

            int index = (line * WIDTH + col) * 3;
            if (i >= MAX_ITER) {
                pixels[index] = 0; pixels[index+1] = 0; pixels[index+2] = 0;
            } else {
                pixels[index] = (4 * i) % 256;
                pixels[index+1] = (2 * i) % 256;
                pixels[index+2] = (6 * i) % 256;
            }
        }
    }

    double end = omp_get_wtime();
    printf("Time: %f\n", end - start);

    save_dummy(pixels);
    free(pixels);
    return 0;
}
