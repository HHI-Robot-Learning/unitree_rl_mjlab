#!/bin/bash
#SBATCH --account=cpu
#SBATCH --partition=ber-amd1
#SBATCH --cpus-per-task=8
#SBATCH --mem=32G
#SBATCH --time=01:00:00
#SBATCH --job-name=unitree_venv
#SBATCH --output=cluster/logs/%x_%j.out
#
# Build unitree_venv.sqfs ON BER1, submitted from the repo root:
#
#   mkdir -p cluster/logs && sbatch cluster/build_venv.sh
#
# The runtime is the 26-MOGB B200 image (Python 3.12 at /opt/uv-python, git, EGL,
# ffmpeg) with this squashfs mounted at /opt/unitree_venv. BER1 cannot build images:
# both a %post section and unpacking a .sif as a build base need a user namespace
# that apparmor blocks. Mounting a squashfs needs none.
#
# The venv is created from uv.lock at its final path inside the base image, so its
# interpreter links resolve to the base image's Python. Scratch goes to node-local
# $LOCAL_JOB_DIR; the one squashfs file is copied back once.
set -euo pipefail

REPO="${SLURM_SUBMIT_DIR}"
cd "$REPO"
UV_VERSION="0.12.3"
source cluster/runtime.sh

source /etc/slurm/local_job_dir.sh
VENV_DIR="$LOCAL_JOB_DIR/unitree_venv"
VENV_SQUASHFS="$LOCAL_JOB_DIR/unitree_venv.sqfs"
mkdir -p "$VENV_DIR" "$LOCAL_JOB_DIR/uv_bin"

echo "== node       $(hostname)"
echo "== apptainer  $(apptainer --version)"
echo "== commit     $(git rev-parse --short HEAD)"
echo "== base       $BASE_IMAGE"

# The uv that wrote uv.lock, not the base image's older one.
curl -LsSf "https://github.com/astral-sh/uv/releases/download/$UV_VERSION/uv-x86_64-unknown-linux-gnu.tar.gz" \
    | tar xz -C "$LOCAL_JOB_DIR/uv_bin" --strip-components 1

apptainer exec \
    --bind "$REPO":/opt/unitree_build \
    --bind "$VENV_DIR":/opt/unitree_venv \
    --bind "$LOCAL_JOB_DIR" \
    --env UV_PROJECT_ENVIRONMENT=/opt/unitree_venv \
    --env UV_PYTHON_INSTALL_DIR=/opt/uv-python \
    --env UV_PYTHON_DOWNLOADS=never \
    --env UV_LINK_MODE=copy \
    --env UV_CACHE_DIR="$LOCAL_JOB_DIR/uv_cache" \
    --pwd /opt/unitree_build \
    "$BASE_IMAGE" "$LOCAL_JOB_DIR/uv_bin/uv" sync --frozen --no-install-project --no-dev

mksquashfs "$VENV_DIR" "$VENV_SQUASHFS" -noappend -quiet -processors "$SLURM_CPUS_PER_TASK"

# Fail here, not in the first training job, if the venv cannot run on a B200.
run_in_runtime "$VENV_SQUASHFS" python /work/code/cluster/verify_image.py

# One explicit copy back; never via $LOCAL_JOB_DIR/results (its epilog autocopy pins the node).
cp -f "$VENV_SQUASHFS" "$REPO/unitree_venv.sqfs"
ls -la "$REPO/unitree_venv.sqfs"
