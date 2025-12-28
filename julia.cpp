#include <iostream>
#include <vector>
#include <fstream>

// Configuration
const int TAILLE = 10000;
const int ITERATION_MAX = 1000;

// Paramètres Julia
const double XMIN = -1.0;
const double XMAX = 1.0;
const double YMIN = -1.0;
const double YMAX = 1.0;
const double A = -0.8;
const double B = 0.156;

void sauvegarder_image(const std::vector<unsigned char>& buffer) {
    std::cout << "Sauvegarde de l'image..." << std::endl;
    std::ofstream fichier("julia.ppm", std::ios::binary);
    
    if (!fichier) {
        std::cerr << "Erreur ouverture fichier" << std::endl;
        return;
    }

    // En-tête PPM
    fichier << "P6\n" << TAILLE << " " << TAILLE << "\n255\n";
    // Écriture des données
    fichier.write(reinterpret_cast<const char*>(buffer.data()), buffer.size());
    
    std::cout << "Image sauvegardée sous 'julia.ppm' !" << std::endl;
}

int main() {
    // 1. Allocation mémoire automatique avec vector (plus sûr que malloc)
    // On utilise try/catch car 300Mo c'est gros
    std::vector<unsigned char> pixels;
    try {
        pixels.resize((size_t)TAILLE * TAILLE * 3);
    } catch (const std::bad_alloc& e) {
        std::cerr << "Erreur : Pas assez de mémoire !" << std::endl;
        return 1;
    }

    std::cout << "Début du calcul (C++)..." << std::endl;

    // 2. Double boucle de calcul
    for (int line = 0; line < TAILLE; line++) {
        for (int col = 0; col < TAILLE; col++) {
            
            double x = XMIN + col * (XMAX - XMIN) / (double)TAILLE;
            double y = YMAX - line * (YMAX - YMIN) / (double)TAILLE;
            
            int i = 0;
            // Algorithme Z = Z² + C
            while (i <= ITERATION_MAX && (x * x + y * y) <= 4.0) {
                double x_new = x * x - y * y + A;
                double y_new = 2 * x * y + B;
                x = x_new;
                y = y_new;
                i++;
            }

            // Couleurs
            unsigned char r, g, b_color;
            if (i > ITERATION_MAX) {
                r = 0; g = 0; b_color = 0;
            } else {
                r = (4 * i) % 256;
                g = (2 * i) % 256;
                b_color = (6 * i) % 256;
            }

            size_t index = ((size_t)line * TAILLE + col) * 3;
            pixels[index] = r;
            pixels[index + 1] = g;
            pixels[index + 2] = b_color;
        }
    }

    // 3. Sauvegarde
    sauvegarder_image(pixels);

    return 0;
}