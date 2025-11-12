import numpy as np
from mpi4py import MPI
import matplotlib.pyplot as plt

comm = MPI.COMM_WORLD
rank = comm.Get_rank()
size = comm.Get_size()

# Paramètres pour configuration lente
taille = 900
xmin, xmax = -1, 1
ymin, ymax = -1, 1
iterationmax = 100
a = -0.8
b = 0.156

# Division des lignes entre processus
lines_per_proc = taille // size
extra = taille % size
start_line = rank * lines_per_proc + min(rank, extra)
num_lines = lines_per_proc + 1 if rank < extra else lines_per_proc

# Pixels locaux
local_pixels = np.zeros((taille, num_lines, 3), dtype=np.uint8)

for local_line in range(num_lines):
    line = start_line + local_line
    for col in range(taille):
        i = 1
        x = xmin + col * (xmax - xmin) / taille
        y = ymax - line * (ymax - ymin) / taille
        while i <= iterationmax and (x**2 + y**2) <= 4:
            x_temp = x**2 - y**2 + a
            y = 2 * x * y + b
            x = x_temp
            i += 1
        if i > iterationmax and (x**2 + y**2) <= 4:
            local_pixels[col, local_line] = (0, 0, 0)
        else:
            local_pixels[col, local_line] = ((4 * i) % 256, (2 * i) % 256, (6 * i) % 256)

# Gather des pixels
pixels = None
if rank == 0:
    pixels = np.zeros((taille, taille, 3), dtype=np.uint8)

# Calcul des counts et displs pour Gatherv
sendbuf = local_pixels.reshape(-1)
recv_counts = comm.gather(num_lines * taille * 3, root=0)
displs = None
if rank == 0:
    displs = [0]
    for i in range(1, size):
        displs.append(displs[i-1] + recv_counts[i-1])

comm.Gatherv(sendbuf, [pixels, recv_counts, displs, MPI.UINT8_T], root=0)

if rank == 0:
    plt.imsave('julia.png', pixels)
