# Optimisation Énergétique : Fractale de Julia

Ce projet explore l'impact des stratégies de parallélisation sur la consommation énergétique d'un calcul intensif (génération d'une fractale de Julia 10k x 10k).

Réalisé dans le cadre du module **Systèmes Embarqués & Énergie** (Master 2 SECIL).

## 🎯 Objectifs
- Comparer l'efficacité énergétique des stratégies de scheduling OpenMP (**Static** vs **Dynamic**).
- Analyser le compromis Puissance/Temps (stratégie **"Race-to-Halt"**).
- Mesurer la consommation réelle (CPU + RAM) sur **Grid'5000** via l'outil **MojitO/S**.

## 📂 Structure du projet

- `julia_omp.c` : Code source C de la fractale. Utilise `schedule(runtime)` pour une configuration dynamique via le shell.
- `run_bench.sh` : Script d'automatisation. Pilote la fréquence (cpufreq), les threads OpenMP, et lance le monitoring MojitO/S.
- `rapport_energie.pdf` : Analyse détaillée des résultats.
- `resultats.csv` : Données brutes des expériences.

## 🚀 Utilisation

### 1. Pré-requis
- Un environnement Linux avec `gcc` et support OpenMP.
- Accès root (ou `sudo-g5k` sur Grid'5000) pour la lecture des sondes RAPL.
- L'outil [MojitO/S](https://gitlab.irit.fr/sepia-pub/mojitos) doit être compilé et accessible.

### 2. Compilation
Le programme est compilé avec l'option `-O3` et le support OpenMP :

```bash
gcc -O3 -fopenmp julia_omp.c -o julia_omp
