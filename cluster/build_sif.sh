#!/bin/bash
#SBATCH --account=cpu
#SBATCH --partition=ber-amd1
#SBATCH --cpus-per-task=8
#SBATCH --mem=32G
#SBATCH --time=01:00:00
#SBATCH --job-name=unitree_sif
#SBATCH --output=cluster/logs/%x_%j.out
#
# Build unitree_rl_mjlab.sif ON BER1, submitted from the repo root:
#
#   mkdir -p cluster/logs && sbatch cluster/build_sif.sh
#
# 1. Create the venv from uv.lock at its final path /opt/unitree_venv, inside the
#    base image, so its interpreter links resolve to the base image's Python.
# 2. Build the image from the base image plus that venv, with no %post.
# All scratch goes to node-local $LOCAL_JOB_DIR; the image is copied back once.
set -euo pipefail

REPO="${SLURM_SUBMIT_DIR}"
cd "$REPO"
BASE_IMAGE="/data/cluster/users/$USER/26-MOGB/sgrl-ber1.sif"
UV_VERSION="0.12.3"

source /etc/slurm/local_job_dir.sh
BUILD_DIR="$LOCAL_JOB_DIR/build"
mkdir -p "$BUILD_DIR/unitree_venv" "$LOCAL_JOB_DIR/uv_bin"
export APPTAINER_TMPDIR="$LOCAL_JOB_DIR/apptainer_tmp"
export APPTAINER_CACHEDIR="$LOCAL_JOB_DIR/apptainer_cache"
mkdir -p "$APPTAINER_TMPDIR" "$APPTAINER_CACHEDIR"

echo "== node       $(hostname)"
echo "== apptainer  $(apptainer --version)"
echo "== commit     $(git rev-parse --short HEAD)"
echo "== base       $BASE_IMAGE"

# The uv that wrote uv.lock, not the base image's older one.
curl -LsSf "https://github.com/astral-sh/uv/releases/download/$UV_VERSION/uv-x86_64-unknown-linux-gnu.tar.gz" \
    | tar xz -C "$LOCAL_JOB_DIR/uv_bin" --strip-components 1

export APPTAINERENV_UV_PROJECT_ENVIRONMENT=/opt/unitree_venv
export APPTAINERENV_UV_PYTHON_INSTALL_DIR=/opt/uv-python
export APPTAINERENV_UV_PYTHON_DOWNLOADS=never
export APPTAINERENV_UV_LINK_MODE=copy
export APPTAINERENV_UV_CACHE_DIR="$LOCAL_JOB_DIR/uv_cache"
apptainer exec \
    --bind "$REPO":/opt/unitree_build \
    --bind "$BUILD_DIR/unitree_venv":/opt/unitree_venv \
    --bind "$LOCAL_JOB_DIR" \
    --pwd /opt/unitree_build \
    "$BASE_IMAGE" "$LOCAL_JOB_DIR/uv_bin/uv" sync --frozen --no-install-project --no-dev

cp cluster/unitree_rl_mjlab.def "$BUILD_DIR/"
cd "$BUILD_DIR"
apptainer build --force unitree_rl_mjlab.sif unitree_rl_mjlab.def

# Fail here, not in the first training job, if the image cannot run on a B200.
apptainer exec --bind "$REPO":/work/code "$BUILD_DIR/unitree_rl_mjlab.sif" \
    python /work/code/cluster/verify_image.py

# One explicit copy back; never via $LOCAL_JOB_DIR/results (its epilog autocopy pins the node).
cp -f "$BUILD_DIR/unitree_rl_mjlab.sif" "$REPO/unitree_rl_mjlab.sif"
ls -la "$REPO/unitree_rl_mjlab.sif"
