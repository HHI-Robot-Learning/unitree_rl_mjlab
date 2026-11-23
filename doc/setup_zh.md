# 安装指南

## 系统要求

- **操作系统**：推荐使用 Ubuntu 22.04
- **显卡**：Nvidia 显卡
- **驱动版本**：建议使用 550 或更高版本

---

## 1. 安装 uv

项目环境由 [uv](https://docs.astral.sh/uv/) 管理：

```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
```

---

## 2. 安装

### 2.1 下载项目

```bash
git clone https://github.com/unitreerobotics/unitree_rl_mjlab.git
```

### 2.2 安装依赖

```bash
sudo apt install -y libyaml-cpp-dev libboost-all-dev libeigen3-dev libspdlog-dev libfmt-dev
```

所有 Python 依赖都固定在 `pyproject.toml` 和 `uv.lock` 中。在 `.venv` 中创建环境：

```bash
cd unitree_rl_mjlab
uv sync
```

所有脚本都通过该环境运行，例如 `uv run python scripts/train.py Unitree-G1-Flat`。

### 2.3 torch 版本的显卡支持

`torch` 从 CUDA 12.6 的 wheel 源安装，支持 Volta（V100）到 Hopper（H100）显卡。Blackwell 显卡（RTX 50xx、RTX PRO、B200）
需要 CUDA 12.8 版本：将 `pyproject.toml` 中的源 `url` 改为 `https://download.pytorch.org/whl/cu128`，然后重新运行 `uv sync`。
