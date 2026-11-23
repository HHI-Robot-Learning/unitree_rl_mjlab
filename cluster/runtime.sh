# Sourced by the cluster scripts. The runtime = the 26-MOGB B200 base image with
# the unitree venv squashfs mounted at /opt/unitree_venv and the repo at /work/code.
BASE_IMAGE="/data/cluster/users/$USER/26-MOGB/sgrl-ber1.sif"

# run_in_runtime <venv squashfs> <command...>; `python` is the unitree venv's.
run_in_runtime() {
    local venv_squashfs="$1"
    shift
    apptainer exec --nv \
        --bind "$REPO":/work/code \
        --bind "$venv_squashfs":/opt/unitree_venv:image-src=/ \
        --env PATH=/opt/unitree_venv/bin:/usr/local/bin:/usr/bin:/bin \
        --env VIRTUAL_ENV=/opt/unitree_venv \
        --env PYTHONPATH=/work/code \
        "${RUNTIME_OPTIONS[@]}" \
        "$BASE_IMAGE" "$@"
}
RUNTIME_OPTIONS=()
