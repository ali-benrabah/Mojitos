#!/bin/bash


if [ -f "../mojitos/bin/mojitos" ]; then MOJITOS_BIN="../mojitos/bin/mojitos"
elif [ -f "$HOME/mojitos/bin/mojitos" ]; then MOJITOS_BIN="$HOME/mojitos/bin/mojitos"
elif [ -f "./mojitos/bin/mojitos" ]; then MOJITOS_BIN="./mojitos/bin/mojitos"
else echo "Erreur: Mojitos introuvable"; exit 1; fi

APP="./julia_omp"
OUTPUT="resultats_complets.csv"


echo "Strategie,Threads,Frequence_Hz,Temps_s,Energie_J,Puissance_W" > $OUTPUT

FREQS=("Max")
THREADS=(4 16) 
STRATEGIES=("static" "dynamic") 

echo "Démarrage du benchmark avancé..."

for sched in "${STRATEGIES[@]}"; do
    
    export OMP_SCHEDULE=$sched
    
    for t in "${THREADS[@]}"; do
        export OMP_NUM_THREADS=$t
        
        for f in "${FREQS[@]}"; do
            if [ "$f" == "Max" ]; then
                 sudo-g5k cpupower frequency-set -g performance > /dev/null 2>&1
                 REAL_F="3.9GHz"
            else
                 sudo-g5k cpupower frequency-set -f ${f}kHz > /dev/null 2>&1
                 REAL_F=$f
            fi
            
            echo "------------------------------------------------"
            echo "Test : Stratégie=$sched | Threads=$t | Freq=$REAL_F"

            RES=$(sudo-g5k $MOJITOS_BIN -r -f 10 -o /tmp/run.log -- env OMP_NUM_THREADS=$t OMP_SCHEDULE=$sched $APP)
            
            TIME=$(echo "$RES" | grep "Time:" | awk '{print $2}')
            if [ -z "$TIME" ]; then TIME=0; fi

            # Calcul Energie
            ENERGY=$(python3 -c "
import pandas as pd
try:
    df = pd.read_csv('/tmp/run.log', sep=' ')
    cols = df.columns
    c_cpu = next((c for c in cols if 'package' in c or 'pkg' in c), None)
    c_ram = next((c for c in cols if 'dram' in c or 'ram' in c), None)
    val = 0
    if c_cpu: val += df[c_cpu].sum()
    if c_ram: val += df[c_ram].sum()
    print(val / 1000000.0)
except:
    print(0)
")
            POWER=$(python3 -c "print($ENERGY / $TIME if $TIME > 0 else 0)")

            echo "  -> $TIME s | $ENERGY J"
            echo "$sched,$t,$REAL_F,$TIME,$ENERGY,$POWER" >> $OUTPUT
        done
    done
done

echo "------------------------------------------------"
cat $OUTPUT
