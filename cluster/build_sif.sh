#!/bin/bash
#SBATCH --partition=gpu1,gpu3,gpu4,gpu5
#SBATCH --cpus-per-task=8
#SBATCH --mem=32G
#SBATCH --time=02:00:00
#SBATCH --job-name=unitree_sif
#SBATCH --output=cluster/logs/%x_%j.out
#
# Build unitree_rl_mjlab.sif. Runs ON VCA, submitted from the repo root:
#
#   mkdir -p cluster/logs && sbatch cluster/build_sif.sh
#
# VCA, because BER1 cannot run a %post section (apparmor blocks the unprivileged
# user namespace, no /etc/subuid entry). A CPU-only job: nothing here needs a GPU.
# All scratch goes to node-local $LOCAL_JOB_DIR; apptainer's default cache is $HOME.
set -euo pipefail

REPO="${SLURM_SUBMIT_DIR}"
cd "$REPO"

source /etc/slurm/local_job_dir.sh
export APPTAINER_TMPDIR="$LOCAL_JOB_DIR/apptainer_tmp"
export APPTAINER_CACHEDIR="$LOCAL_JOB_DIR/apptainer_cache"
mkdir -p "$APPTAINER_TMPDIR" "$APPTAINER_CACHEDIR"

echo "== node       $(hostname)"
echo "== apptainer  $(apptainer --version)"
echo "== commit     $(git rev-parse --short HEAD)"

# The viwiki command as written. Never add --ignore-fakeroot-command: on VCA it
# breaks dpkg's chown during the apt install.
IMAGE_IN_SCRATCH="$LOCAL_JOB_DIR/unitree_rl_mjlab.sif"
apptainer build --fakeroot --force "$IMAGE_IN_SCRATCH" cluster/unitree_rl_mjlab.def

# One explicit copy back; never via $LOCAL_JOB_DIR/results (its epilog autocopy pins the node).
cp -f "$IMAGE_IN_SCRATCH" "$REPO/unitree_rl_mjlab.sif"
ls -la "$REPO/unitree_rl_mjlab.sif"
