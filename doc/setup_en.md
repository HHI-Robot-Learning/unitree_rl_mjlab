# Installation Guide

## System Requirements

- **Operating System**: Recommended Ubuntu 22.04
- **GPU**: Nvidia GPU
- **Driver Version**: Recommended version 550 or later

---

## 1. Install uv

The project environment is managed with [uv](https://docs.astral.sh/uv/):

```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
```

---

## 2. Installing

### 2.1 Download the Project

```bash
git clone https://github.com/unitreerobotics/unitree_rl_mjlab.git
```

### 2.2 Install Dependencies

```bash
sudo apt install -y libyaml-cpp-dev libboost-all-dev libeigen3-dev libspdlog-dev libfmt-dev
```

All Python dependencies are pinned in `pyproject.toml` and `uv.lock`. Create the environment in `.venv` with:

```bash
cd unitree_rl_mjlab
uv sync
```

Run every script through the environment, e.g. `uv run python scripts/train.py Unitree-G1-Flat`.

### 2.3 GPU support of the torch build

`torch` is installed from the CUDA 12.6 wheel index, which covers Volta (V100) up to Hopper (H100) GPUs. Blackwell
GPUs (RTX 50xx, RTX PRO, B200) need the CUDA 12.8 build: change the index `url` in `pyproject.toml` to
`https://download.pytorch.org/whl/cu128` and run `uv sync` again.
