#!/bin/bash

# --- 1. DÉTECTION INTELLIGENTE DE MOJITOS ---
# On cherche l'outil dans le dossier d'à côté (../mojitos)
# ou dans le dossier personnel ($HOME/mojitos)

if [ -f "../mojitos/bin/mojitos" ]; then
    # Cas 1 : Le dossier 'mojitos' est juste à côté de 'Mojitos'
    MOJITOS_BIN="../mojitos/bin/mojitos"
elif [ -f "$HOME/mojitos/bin/mojitos" ]; then
    # Cas 2 : On le trouve via le chemin absolu
    MOJITOS_BIN="$HOME/mojitos/bin/mojitos"
elif [ -f "./mojitos/bin/mojitos" ]; then
    # Cas 3 : Il est dans un sous-dossier (ancienne version)
    MOJITOS_BIN="./mojitos/bin/mojitos"
else
    echo "ERREUR CRITIQUE : Je ne trouve pas le programme 'mojitos'."
    echo "Je l'ai cherché ici : ../mojitos/bin/mojitos"
    echo "Vérifie que tu as bien fait le 'make' dans le dossier mojitos."
    exit 1
fi

echo "-> Outil MojitO/S trouvé : $MOJITOS_BIN"

# --- 2. VÉRIFICATION DE L'APPLICATION ---
APP="./julia_omp"
if [ ! -f "$APP" ]; then
    echo "ERREUR : L'application $APP n'existe pas."
    echo "Compile-la avec : gcc -O3 -fopenmp julia_omp.c -o julia_omp"
    exit 1
fi

# --- 3. LANCEMENT DU BENCHMARK ---
OUTPUT="resultats_final.csv"
rm -f $OUTPUT
echo "Threads,Frequence_Hz,Temps_s,Energie_J,Puissance_W" > $OUTPUT

# Paramètres
FREQS=("2000000" "Max") 
THREADS=(1 4 8 16)

echo "Démarrage des mesures..."

for t in "${THREADS[@]}"; do
    export OMP_NUM_THREADS=$t
    
    for f in "${FREQS[@]}"; do
        # Changement de fréquence (avec sudo-g5k)
        if [ "$f" == "Max" ]; then
             sudo-g5k cpupower frequency-set -g performance > /dev/null 2>&1
             REAL_F="Performance"
        else
             sudo-g5k cpupower frequency-set -f ${f}kHz > /dev/null 2>&1
             REAL_F=$f
        fi
        
        echo "Test : Threads=$t, Freq=$REAL_F"

        # Exécution (Capture du temps et mesure énergie)
        RES=$(sudo-g5k $MOJITOS_BIN -r -f 10 -o /tmp/run.log -- env OMP_NUM_THREADS=$t $APP)
        
        # Extraction du temps affiché par le programme C
        TIME=$(echo "$RES" | grep "Time:" | awk '{print $2}')
        
        # Sécurité si le temps est vide (évite le crash Python)
        if [ -z "$TIME" ]; then TIME=0; fi

        # Calcul de l'énergie (CPU + RAM) via Python
        ENERGY=$(python3 -c "
import pandas as pd
try:
    df = pd.read_csv('/tmp/run.log', sep=' ')
    cols = df.columns
    # Détection automatique des colonnes CPU et RAM
    c_cpu = next((c for c in cols if 'package' in c or 'pkg' in c), None)
    c_ram = next((c for c in cols if 'dram' in c or 'ram' in c), None)
    
    val = 0
    if c_cpu: val += df[c_cpu].sum()
    if c_ram: val += df[c_ram].sum()
    
    # Conversion micro-joules -> Joules
    print(val / 1000000.0)
except:
    print(0)
")
        
        # Calcul Puissance (Watts)
        POWER=$(python3 -c "print($ENERGY / $TIME if $TIME > 0 else 0)")

        echo "  -> Résultat : ${TIME}s | ${ENERGY}J | ${POWER}W"
        echo "$t,$REAL_F,$TIME,$ENERGY,$POWER" >> $OUTPUT
    done
done

echo "------------------------------------------------"
echo "Terminé ! Résultats sauvegardés dans $OUTPUT"
cat $OUTPUT
