#!/bin/bash
#SBATCH --nodes=3
#SBATCH --ntasks-per-node=128
#SBATCH --cpus-per-task=1
#SBATCH --time=00:20:00

#SBATCH --account=[budget code]
#SBATCH --partition=standard
#SBATCH --qos=short

# activate conda env if needed
export PREFIX=/path/to/install/location
eval "$($PREFIX/miniconda3/bin/conda shell.bash hook)" 
conda activate a2-smartsim

export SMARTSIM_LOG_LEVEL=debug
export SR_LOG_LEVEL=debug

python launch_database_cluster.py

