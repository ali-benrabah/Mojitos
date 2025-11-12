#!/bin/bash
# measure.sh <freq_khz> <command> [args...]
# Exemple : ./measure.sh 4200000 ./julia_c
#./measure.sh 1400000 mpirun -np 4 python3 julia_py.py
# version 2
FREQ=$1
shift
CMD="$@"
CSV="/tmp/mojitos_energy.csv"

# --- Vérifications ---
if [ -z "$FREQ" ] || [ -z "$CMD" ]; then
    echo "Usage: $0 <freq_khz> <command> [args...]"
    exit 1
fi

# --- Fixer la fréquence ---
sudo sh -c "echo $FREQ > /sys/devices/system/cpu/cpu*/cpufreq/scaling_max_freq"
echo "Fréquence fixée à $FREQ kHz"

# --- Lancer MojitO/S en arrière-plan ---
sudo ./bin/mojitos -r -f 50 -o "$CSV" &
MOJITOS_PID=$!
sleep 0.2  # laisser le temps d’initialiser

# --- Exécuter la commande ---
start=$(date +%s.%N)
eval $CMD
exit_code=$?
end=$(date +%s.%N)

# --- Arrêter MojitO/S proprement ---
sudo kill $MOJITOS_PID
wait $MOJITOS_PID 2>/dev/null || true

# --- Calcul des métriques ---
python3 - <<PY
import pandas as pd
df = pd.read_csv("$CSV", sep=r'\s+', engine='python')
df = df.loc[:, ~df.columns.str.contains('^Unnamed')]  # nettoyer

# RAPL Intel: package-0, dram0, etc. (micro-joules)
rapl_cols = [c for c in df.columns if 'package' in c or 'dram' in c or 'pp0' in c]
energy_uj = (df[rapl_cols].iloc[-1] - df[rapl_cols].iloc[0]).sum()
energy_j = energy_uj / 1e6

time_s = df['#timestamp'].iloc[-1] - df['#timestamp'].iloc[0]
if time_s == 0: time_s = 0.001

# Puissance max sur un intervalle
df['delta_e'] = df[rapl_cols].sum(axis=1).diff()
df['delta_t'] = df['#timestamp'].diff()
df['power_w'] = df['delta_e'] / df['delta_t'] / 1e6
max_power = df['power_w'].max()

print(f"{time_s:.2f} {energy_j:.0f} {max_power:.1f}")
PY

# --- Reset fréquence ---
fmax=$(cat /sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_max_freq)
sudo sh -c "echo $fmax > /sys/devices/system/cpu/cpu*/cpufreq/scaling_max_freq"
echo "Fréquence restaurée à $fmax kHz"

exit $exit_code

if rank == 0:
    plt.imsave('julia.png', pixels)
