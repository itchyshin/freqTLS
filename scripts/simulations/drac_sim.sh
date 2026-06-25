#!/bin/bash
# ============================================================================
# Run the freqTLS (ML/TMB) simulation on a DRAC general-purpose cluster.
#
# One-time env build (login node -- compute nodes have no internet):
#   bash install_deps.sh        # installs deps + freqTLS into Rlib/ (see below)
#
# Submit (from the synced repo root /project/def-snakagaw/snakagaw/freqTLS-sim/freqTLS):
#   Single job, all scenarios, relative threshold (fast):
#     sbatch scripts/simulations/drac_sim.sh
#   Job array, one scenario per task (recommended for the heavy run):
#     sbatch --array=1-29 scripts/simulations/drac_sim.sh
#   Heavy: array + the absolute-threshold/T_crit bootstrap (NBOOT>0):
#     sbatch --array=1-29 --export=ALL,NBOOT=500 scripts/simulations/drac_sim.sh
#
# Golden rules honoured: never runs on a login node (this is the sbatch body);
# R library + source live on /project (never /scratch); --account/--time set.
# ============================================================================
#SBATCH --account=def-snakagaw
#SBATCH --job-name=freqtls-sim
#SBATCH --time=2:00:00
#SBATCH --cpus-per-task=16
#SBATCH --mem=24G
#SBATCH --output=freqtls-sim-%A_%a.out

set -uo pipefail
module load StdEnv/2023 gcc/12.3 r/4.4.0
export R_LIBS_USER=/project/def-snakagaw/snakagaw/freqTLS-sim/Rlib
REPO=/project/def-snakagaw/snakagaw/freqTLS-sim/freqTLS
cd "$REPO"; touch .here        # anchor here::here() (.git is not synced)

export N_SIMS=${N_SIMS:-1000}
export NBOOT=${NBOOT:-0}
export WORKERS=${SLURM_CPUS_PER_TASK:-16}

# Scenario labels in the runner's table order (array index -> scenario).
LABELS=(scen1_strict_eq_n3 scen1_strict_eq_n5 scen2_lik_misspec_n3 scen2_lik_misspec_n5 \
  scen3_heat_lowers_u_n3 scen3_heat_lowers_u_n5 scen4_compress_n3 scen4_compress_n5 \
  scen5_sharpen_n3 scen5_sharpen_n5 scen6_ub_m005 scen6_ub_m010 scen6_ub_m015 scen6_ub_m019 \
  scen7_u0_099 scen7_u0_095 scen7_u0_085 scen7_u0_075 scen7_u0_065 \
  scen8_full_n1 scen8_full_n3 scen8_full_n5 scen8_sparse_n1 scen8_sparse_n3 scen8_sparse_n5 \
  scen9_tmax_060 scen9_tmax_120 scen9_tmax_240 scen9_tmax_405)

if [[ -n "${SLURM_ARRAY_TASK_ID:-}" ]]; then
  SCEN=${LABELS[$((SLURM_ARRAY_TASK_ID-1))]}
  export OUT_TAG="$SCEN"
  echo "array task $SLURM_ARRAY_TASK_ID -> $SCEN  (N_SIMS=$N_SIMS NBOOT=$NBOOT WORKERS=$WORKERS)  $(hostname)  $(date)"
  Rscript scripts/simulations/run_simulations.R "$SCEN"
else
  export OUT_TAG="${OUT_TAG:-drac_full}"
  echo "single job: all scenarios  (N_SIMS=$N_SIMS NBOOT=$NBOOT WORKERS=$WORKERS)  $(hostname)  $(date)"
  Rscript scripts/simulations/run_simulations.R all
fi
echo "DONE $(date) -- 'seff ${SLURM_JOB_ID:-?}' for resource usage"
