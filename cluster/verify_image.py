import argparse

import mujoco
import mujoco_warp
import torch
import warp


def check_build() -> None:
    # get_arch_list() is empty without a visible driver; the compiled-in flags need no device.
    arch_flags = torch._C._cuda_getArchFlags()
    print(f"torch        {torch.__version__}  cuda {torch.version.cuda}")
    print(f"arch flags   {arch_flags}")
    print(f"mujoco       {mujoco.__version__}")
    print(f"warp-lang    {warp.config.version}")
    assert torch.version.cuda.startswith("13."), f"not a CUDA 13 build: {torch.version.cuda}"
    assert "sm_100" in arch_flags, f"no sm_100 code, cannot run on a B200: {arch_flags}"
    print("BUILD OK     CUDA 13 with sm_100 code")


def check_device() -> None:
    assert torch.cuda.is_available(), "no CUDA device visible; was the job given --nv and a GPU?"
    major, minor = torch.cuda.get_device_capability(0)
    print(f"device       {torch.cuda.get_device_name(0)}  sm_{major}{minor}")
    # A real kernel launch: an image without code for this card reports the GPU fine and dies here.
    for dtype in (torch.float32, torch.bfloat16):
        left = torch.randn(4096, 4096, device="cuda", dtype=dtype)
        right = torch.randn(4096, 4096, device="cuda", dtype=dtype)
        product = left @ right
        torch.cuda.synchronize()
        assert torch.isfinite(product.float()).all(), f"{dtype} matmul produced non-finite values"
        print(f"matmul       {dtype} ok")
    warp.init()
    print(f"mujoco-warp  imported from {mujoco_warp.__file__}")
    print("DEVICE OK    kernels launch from this image")


parser = argparse.ArgumentParser()
parser.add_argument("--device", action="store_true", help="also launch kernels on a visible GPU")
arguments = parser.parse_args()

check_build()
if arguments.device:
    check_device()
