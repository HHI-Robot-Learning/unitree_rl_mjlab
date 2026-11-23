#!/bin/bash
# Run scripts/train.py in the runtime (see cluster/runtime.sh) on one BER1 B200. Arguments go to train.py.
# Submitted from the repo root on BER1 through the shared wrapper:
#
#   ~/scheduling/submit.sh 'bash cluster/train_ber1.sh Unitree-G1-Flat --env.scene.num-envs=4096'
#
# Every write of the run (logs/, checkpoints, wandb files, warp/triton caches, $HOME)
# goes to node-local $LOCAL_JOB_DIR. logs/ is copied back to the repo once, on exit,
# including when slurm ends the job with SIGTERM.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$REPO/cluster/runtime.sh"

source /etc/slurm/local_job_dir.sh
RUN_DIR="$LOCAL_JOB_DIR/run"
CONTAINER_HOME="$LOCAL_JOB_DIR/home"
mkdir -p "$RUN_DIR" "$CONTAINER_HOME"

# WANDB_API_KEY and WANDB_ENTITY; rsl-rl reads the entity from WANDB_USERNAME.
set -a
source "$REPO/.env"
set +a
export WANDB_USERNAME="$WANDB_ENTITY"
export WANDB_DIR="$RUN_DIR"
export XDG_CACHE_HOME="$LOCAL_JOB_DIR/cache"
export WARP_CACHE_PATH="$LOCAL_JOB_DIR/cache/warp"
export TRITON_CACHE_DIR="$LOCAL_JOB_DIR/cache/triton"

copy_logs_back() {
    if [ -d "$RUN_DIR/logs" ]; then
        mkdir -p "$REPO/logs"
        cp -r "$RUN_DIR/logs/." "$REPO/logs/"
        echo "== logs copied back to $REPO/logs"
    fi
}
trap copy_logs_back EXIT
trap 'exit 143' TERM

echo "== node     $(hostname)  job ${SLURM_JOB_ID}"
echo "== commit   $(git -C "$REPO" rev-parse --short HEAD)"
echo "== scratch  $RUN_DIR"
echo "== train.py $*"

RUNTIME_OPTIONS=(--home "$CONTAINER_HOME" --bind "$LOCAL_JOB_DIR" --pwd "$RUN_DIR")

run_in_runtime "$REPO/unitree_venv.sqfs" python /work/code/cluster/verify_image.py --device
# In the background + wait, so a SIGTERM reaches the TERM trap instead of waiting for train.py.
run_in_runtime "$REPO/unitree_venv.sqfs" python /work/code/scripts/train.py "$@" &
wait $!
