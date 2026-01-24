#include <stdio.h>
#include <stdlib.h>
#include <omp.h>

// Configuration "Rapide" demandée dans le sujet (10000x10000)
#define WIDTH 10000
#define HEIGHT 10000
#define MAX_ITER 1000

// Fonction pour sauvegarder (simulation d'écriture)
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

    // Allocation mémoire
    unsigned char *pixels = (unsigned char *)malloc(WIDTH * HEIGHT * 3);
    if (!pixels) return 1;

    double start = omp_get_wtime();

    // OPTIMISATION CLÉ : schedule(dynamic)
    // Permet de ne pas bloquer les threads sur les zones noires (lentes)
    #pragma omp parallel for schedule(dynamic)
    for (int line = 0; line < HEIGHT; line++) {
        for (int col = 0; col < WIDTH; col++) {
            double x = xmin + col * (xmax - xmin) / WIDTH;
            double y = ymax - line * (ymax - ymin) / HEIGHT;
            int i = 0;
            
            // Calcul de la suite
            while (i < MAX_ITER && (x*x + y*y) <= 4.0) {
                double x_tmp = x*x - y*y + c_real;
                y = 2*x*y + c_imag;
                x = x_tmp;
                i++;
            }

            // Coloriage pixel
            int index = (line * WIDTH + col) * 3;
            pixels[index] = (i >= MAX_ITER) ? 0 : (4 * i) % 256;
            pixels[index+1] = (i >= MAX_ITER) ? 0 : (2 * i) % 256;
            pixels[index+2] = (i >= MAX_ITER) ? 0 : (6 * i) % 256;
        }
    }

    double end = omp_get_wtime();
    printf("Time: %f\n", end - start);

    save_dummy(pixels);
    free(pixels);
    return 0;
}