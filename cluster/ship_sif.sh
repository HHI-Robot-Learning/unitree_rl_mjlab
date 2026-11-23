#!/bin/bash
# Copy the image built on VCA to the BER1 checkout. Runs ON VCA, reached as
# `ssh -A GpuCluster`: the clusters share no home directory, so the hop to BER1
# authenticates with the forwarded agent. BeeGFS to BeeGFS over the HHI network;
# never route the image through the laptop (~0.7 MB/s over the VPN).
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BER1_HOST="hpc-ber1-headnode-01.fe.hhi.de"
BER1_REPO="/data/cluster/users/$USER/unitree_rl_mjlab"

[ -n "${SSH_AUTH_SOCK:-}" ] || { echo "!! no forwarded ssh agent; reconnect with ssh -A GpuCluster" >&2; exit 1; }

# rsync verifies a whole-file checksum after the transfer; --partial resumes an interrupted copy.
rsync -a --partial --inplace -e "ssh -o StrictHostKeyChecking=accept-new" \
    "$REPO/unitree_rl_mjlab.sif" "$BER1_HOST:$BER1_REPO/unitree_rl_mjlab.sif"
ssh "$BER1_HOST" "ls -la $BER1_REPO/unitree_rl_mjlab.sif"
