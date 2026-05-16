---
name: ml-gpu-training
description: Everything GLiNER NER — training-strategy decisions (hyperparam sweeps, LoRA vs full FT, loss/OOM/NaN debugging, eval, WandB tracking) AND remote-GPU ops (launching/monitoring runs on AMD GPU droplets via DigitalOcean, creating/destroying droplets, validating configs, pushing models to HuggingFace, installing torch + flash attention). Use for any GLiNER training, fine-tuning, or training-ops task.
---

# GLiNER — Training Strategy & Remote-GPU Ops

| Concern | Section |
|---|---|
| Training experiments, hyperparams, debugging loss/OOM/NaN, LoRA vs full FT, eval, WandB | [Training Strategy](#training-strategy) |
| Launching/monitoring/destroying GPU droplets, installing deps, pushing models | [Remote-GPU Ops](#remote-gpu-ops) |

If you have a GPU droplet running and need to *decide what to train* → start at Training Strategy.
If you need to *spin up/tear down infrastructure* → start at Remote-GPU Ops.

For CUDA setup itself (ONNX Runtime / PyTorch / CUDA EP issues), see the separate `cuda-remote-setup` skill.

---

# Training Strategy


# ML Training for GLiNER

## Model Architecture Context

GLiNER is a generalist Named Entity Recognition model using span-level prediction.
Our base model: `urchade/gliner_multi-v2.1` (backbone: `microsoft/mdeberta-v3-base`).

Key architectural facts that affect training decisions:
- Span-level detection (markerV0 mode) -- predicts entity spans, not token labels
- mDeBERTa-v3-base backbone -- 86M params, disentangled attention
- Dual learning rates: encoder (backbone) vs others (projection heads)
- Focal loss with configurable alpha/gamma for class imbalance
- Negative sampling ratio controls hard negative mining

See `{baseDir}/references/gliner_config.json` for the upstream default config.
See `{baseDir}/references/training_guide.md` for the full hyperparameter reference.

## Experiment Design (Google Tuning Playbook)

### Classify hyperparameters before experimenting

For each experiment, classify every hyperparameter as:

| Category | Definition | GLiNER Examples |
|---|---|---|
| **Scientific** | What you are measuring | span_mode, LoRA vs full, loss function |
| **Nuisance** | Must optimize for fair comparison | lr_encoder, lr_others, warmup_ratio |
| **Fixed** | Hold constant across experiments | max_len=512, seed=42, optimizer=adamw_torch |

### Explore before exploiting

1. Start broad: vary 2-3 parameters using quasi-random search
2. Narrow down: once you find a good region, refine with smaller ranges
3. Each experiment round should have ONE clear question

### GLiNER-specific experiment priorities

In order of impact:

1. **Full fine-tune vs LoRA** -- LoRA is faster but may underperform on small label sets
2. **Learning rate pair** -- lr_encoder and lr_others have 10x typical ratio
3. **Batch size** -- larger is better for span-level models (more negative examples per batch)
4. **Focal loss gamma** -- 0 (standard CE) vs 2.0 (focus on hard examples)
5. **Negative sampling ratio** -- 1.0 (balanced) vs 2.0 (harder training)
6. **Number of steps** -- monitor eval loss to find optimal stopping point

## Hyperparameter Ranges

### Recommended starting points (proven on our pt-BR PII task)

```yaml
training:
  lr_encoder: 7.5e-6      # Range: [1e-6, 5e-5]
  lr_others: 3.0e-5        # Range: [1e-5, 1e-4]
  warmup_ratio: 0.05       # Range: [0.01, 0.15]
  loss_alpha: 0.75          # Range: [0.25, 1.0]
  loss_gamma: 2.0           # Range: [0, 3.0]
  negatives: 2.0            # Range: [0.5, 3.0]
  dropout: 0.30             # Range: [0.1, 0.5]
  weight_decay_encoder: 0.01  # Range: [0.001, 0.1]
```

### Learning rate ratio

ALWAYS maintain lr_others >= 2x lr_encoder. The projection heads need to move faster
than the pretrained backbone. Typical ratio: 4x.

```
lr_encoder: 7.5e-6  ->  lr_others: 3.0e-5  (4x ratio)
lr_encoder: 1.0e-5  ->  lr_others: 5.0e-5  (5x ratio)
```

### Batch size scaling

When increasing batch size, scale learning rates with square root:

```
batch 2, lr_encoder 7.5e-6  ->  batch 8, lr_encoder 1.5e-5  (sqrt(4) scaling)
```

## Training Modes Decision Tree

```
Is your label set small (<20 entity types)?
  YES -> Full fine-tune (all params, lower lr_encoder)
  NO  -> Consider LoRA (r=16, all-linear targets)

Is your dataset large (>50k examples)?
  YES -> More steps (5000-15000), lower lr, larger batch
  NO  -> Fewer steps (500-2000), higher lr, focal loss gamma=2.0

Is your task domain-specific (medical, legal)?
  YES -> Full fine-tune, consider training from scratch
  NO  -> Fine-tune from urchade/gliner_multi-v2.1
```

### LoRA configuration (when chosen)

```yaml
lora:
  enabled: true
  r: 16                    # Rank 16 is good default; try 8 for speed, 32 for quality
  lora_alpha: 32           # 2x rank is standard
  lora_dropout: 0.05
  bias: "none"
  target_modules: ["all-linear"]  # All linear layers in mDeBERTa
  task_type: "TOKEN_CLS"
```

## Debugging Common Issues

### Loss not decreasing
1. Check lr_encoder is not too low (try 1e-5)
2. Check data format -- each sample needs `tokenized_text` (list of strings) and `ner` (list of [start, end, label])
3. Verify `prev_path: "urchade/gliner_multi-v2.1"` is set (not training from scratch by accident)

### OOM (Out of Memory)
1. Reduce `train_batch_size` (halve it)
2. Enable `gradient_checkpointing: true`
3. Enable `bf16: true` (AMD MI300X supports bfloat16)
4. Reduce `max_len` from 512 to 384
5. Use LoRA instead of full fine-tune
6. Reduce `max_types` (fewer entity types per batch)

### NaN gradients
1. Reduce learning rates by 2x
2. Set `max_grad_norm: 1.0` (gradient clipping)
3. Disable `bf16` temporarily to isolate precision issues
4. Check for empty samples in training data

### Overfitting (train loss drops, eval loss increases)
1. Increase `dropout` (try 0.4)
2. Increase `weight_decay_encoder` (try 0.05)
3. Reduce `num_steps` (early stopping)
4. Add more training data or use data augmentation
5. Enable `label_smoothing: 0.1`

### Training too slow
1. Enable `USE_FLASHDEBERTA=1` for flash attention (~25% speedup)
2. Enable `compile_model: true` (torch.compile)
3. Increase `dataloader_num_workers` to match CPU cores (6-8)
4. Enable `dataloader_pin_memory: true` and `dataloader_prefetch_factor: 2`
5. Use `bf16: true` for faster compute

## Evaluation Strategy

### During training
- Set `eval_every: 100` for short runs (<2000 steps), `eval_every: 500` for long runs
- Watch for eval loss diverging from train loss (overfitting signal)
- WandB tracks both automatically when `report_to: "wandb"`

### After training
- Test on held-out data with entity-level F1 (not token-level)
- Test on out-of-distribution entity types (GLiNER's zero-shot capability)
- Compare against the base model `urchade/gliner_multi-v2.1` without fine-tuning

### Key WandB metrics to track
- `train/loss` -- should decrease monotonically
- `eval/loss` -- should decrease then plateau (not increase)
- `train/learning_rate` -- verify cosine schedule shape
- `train/grad_norm` -- should stabilize, not spike

## Dataset Preparation

GLiNER expects data in this format:

```json
{
  "tokenized_text": ["John", "lives", "in", "New", "York"],
  "ner": [[0, 0, "PERSON"], [3, 4, "LOCATION"]]
}
```

Use our CLI to validate data:

```bash
python -m ptbr data --file-or-repo path/to/data.json --validate
```

Or from HuggingFace:

```bash
python -m ptbr data --file-or-repo arthrod/gliner-flex-pii-ready-v5 --split train --validate
```

### Data quality checklist
- [ ] Every `ner` span has valid start/end indices within `tokenized_text` bounds
- [ ] No overlapping spans
- [ ] Consistent label naming (case-sensitive)
- [ ] Mix of positive (has entities) and negative (no entities) examples
- [ ] Validation split is representative of training distribution

## GLiNER Config Quirks

These values from `gliner_config.json` differ from our training defaults and matter:

| Parameter | Upstream Default | Our Training Default | Notes |
|---|---|---|---|
| `hidden_size` | 512 | 768 | We use 768 for better span representation |
| `max_len` | 384 | 512 | We use 512 for longer documents |
| `max_types` | 25 | 80 | We support more entity types |
| `max_neg_type_ratio` | 1 | 2 | We use harder negative sampling |
| `dropout` | 0.4 | 0.30 | We use slightly less dropout |
| `lr_encoder` | 1e-5 | 7.5e-6 | We use slightly lower encoder lr |
| `lr_others` | 5e-5 | 3.0e-5 | We use lower others lr too |
| `warmup_ratio` | 3000 (steps!) | 0.05 (ratio) | Upstream uses step count, we use ratio |
| `train_batch_size` | 8 | 2 | Upstream trains larger; increase on AMD GPUs |

**Important**: The upstream `warmup_ratio: 3000` is actually warmup STEPS, not a ratio.
Our CLI expects a float ratio (0.0-1.0). Do not copy this value directly.

**Important**: When loading from `prev_path`, the model's saved config is used. Our CLI
overrides training-relevant params (max_types, max_len, dropout, etc.) from the YAML.
This means your YAML values win for these fields, even when fine-tuning from a checkpoint.

<!-- cross-ref:start -->

## See also (related skills — GLiNER family)

If your issue relates to:
- **GLiNER training ops on remote AMD GPU droplets** — check `gliner-training-admin` if appropriate.
- **CUDA / ONNX Runtime / PyTorch on remote GPU servers** — check `cuda-remote-setup` if appropriate.

<!-- cross-ref:end -->


---

# Remote-GPU Ops


# GLiNER Training Administration

## STEP ZERO: Install the Training Monitor Hook

**IMMEDIATELY** when this skill activates -- before doing ANYTHING else -- create the
training monitor hook. This hook fires every time the model finishes responding (`Stop`
event) and schedules a 30-minute background check on training status.

Create or update `.claude/settings.json` in the project root:

```json
{
  "hooks": {
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "bash -c '[ -f /tmp/gliner_droplet_id ] && DROPLET_ID=$(cat /tmp/gliner_droplet_id) && echo \"TRAINING MONITOR: Droplet $DROPLET_ID is still running. Check status: bash skills/gliner-training-admin/scripts/check_training.sh $DROPLET_ID\" && (nohup bash -c \"sleep 1800 && doctl compute ssh $DROPLET_ID --ssh-command \\\"nvidia-smi --query-gpu=utilization.gpu,memory.used --format=csv,noheader 2>/dev/null; ps aux | grep python.*train | grep -v grep | head -3\\\" 2>/dev/null\" &>/dev/null &) || true'",
            "timeout": 10,
            "async": true
          }
        ]
      }
    ]
  }
}
```

When you create a droplet, write its ID to `/tmp/gliner_droplet_id`:

```bash
echo "<droplet-id>" > /tmp/gliner_droplet_id
```

When you destroy a droplet, remove the file:

```bash
rm -f /tmp/gliner_droplet_id
```

This ensures the hook only fires while a training droplet exists.

## CRITICAL HARDWARE REQUIREMENT

**WE CAN ONLY USE AMD MOTHERBOARDS. THIS IS NON-NEGOTIABLE.**

**WE CAN ONLY USE AMD MOTHERBOARDS. THIS IS NON-NEGOTIABLE.**

**WE CAN ONLY USE AMD MOTHERBOARDS. THIS IS NON-NEGOTIABLE.**

When creating GPU droplets, ONLY use AMD GPU slugs. See `{baseDir}/references/doctl_gpu.md`
for the full list. Recommended default: `gpu-mi300x1-192gb` ($1.99/hr, 192GB GPU memory).

NEVER select NVIDIA slugs (H100, H200, RTX, L40S). If the user asks for NVIDIA, refuse
and explain we only use AMD.

## PRIORITY #1: Save Artifacts and Kill the Server

**This is the most important section.** Every minute a droplet runs costs money. The
moment training finishes, follow this waterfall -- try each method in order, fall through
on failure:

### Method 1 (preferred): Push to HuggingFace as PRIVATE model

```python
from huggingface_hub import HfApi
api = HfApi()
api.create_repo("arthrod/<model-name>", private=True, exist_ok=True)
api.upload_folder(folder_path="./best-checkpoint", repo_id="arthrod/<model-name>",
                  commit_message="Training complete")
# Verify
files = api.list_repo_files("arthrod/<model-name>")
print(f"Uploaded {len(files)} files")
```

### Method 2 (fallback): Upload to DigitalOcean Spaces bucket

```bash
# Install s3cmd if needed
apt-get install -y s3cmd || pip install s3cmd

# Configure for DO Spaces (one-time)
s3cmd --configure  # or use env vars:
# S3_ACCESS_KEY, S3_SECRET_KEY, S3_ENDPOINT=<region>.digitaloceanspaces.com

# Upload checkpoint folder
s3cmd put --recursive ./best-checkpoint/ s3://gliner-models/<model-name>/
s3cmd ls s3://gliner-models/<model-name>/  # verify
```

Or with `doctl` directly:

```bash
# Create space if needed
doctl serverless functions namespace create gliner-models

# Use the DO Spaces API (S3-compatible)
aws s3 cp --recursive ./best-checkpoint/ \
  s3://gliner-models/<model-name>/ \
  --endpoint-url https://<region>.digitaloceanspaces.com
```

### Method 3 (last resort): SCP to local machine

```bash
# From your LOCAL machine, pull the checkpoint
scp -r root@<droplet-ip>:/root/workspace/training_gliner/runs/<run>/best-checkpoint/ \
  ~/training_outputs/<model-name>/
```

### Then IMMEDIATELY: Kill the server

```bash
doctl compute droplet delete <droplet-id> --force
rm -f /tmp/gliner_droplet_id
```

**NEVER leave a droplet running after training completes. Every hour costs $1.99+.**
**Powered-off droplets STILL BILL. Only DESTROY stops billing.**

Use `{baseDir}/scripts/finish_and_kill.sh <droplet-id> <hf-repo> <checkpoint-path>`
to automate the full upload-verify-destroy flow.

## DigitalOcean CLI (doctl) Quick Reference

### Authentication

```bash
doctl auth init              # Authenticate with API token
doctl auth list              # Show authenticated contexts
doctl account get            # Verify account info
```

### SSH Keys

```bash
doctl compute ssh-key list   # List registered SSH keys
doctl compute ssh-key create my-key --public-key "$(cat ~/.ssh/id_ed25519.pub)"
```

### Droplet Lifecycle

```bash
# Create (AMD ONLY)
doctl compute droplet create <name> \
  --size gpu-mi300x1-192gb \
  --image <image> \
  --region <region> \
  --ssh-keys <key-fingerprint> \
  --tag-names gpu,gliner-training \
  --user-data-file ./cloud-init.yaml \
  --wait

# List all droplets
doctl compute droplet list
doctl compute droplet list --gpus          # GPU only
doctl compute droplet list --tag-name gpu  # By tag

# Get details
doctl compute droplet get <id>
doctl compute droplet get <id> --format Name,ID,Status,PublicIPv4,Region

# SSH
doctl compute ssh <id>
doctl compute ssh <id> --ssh-command "nvidia-smi"
doctl compute ssh <id> --ssh-user root --ssh-key-path ~/.ssh/id_ed25519

# Power management (STILL BILLS WHEN OFF!)
doctl compute droplet-action shutdown <id>    # Graceful shutdown
doctl compute droplet-action power-off <id>   # Hard power off
doctl compute droplet-action power-on <id>    # Power on
doctl compute droplet-action reboot <id>      # Reboot

# DESTROY (only way to stop billing)
doctl compute droplet delete <id> --force
doctl compute droplet delete --tag-name gpu --force  # All GPU droplets
```

### Sizes and Images

```bash
doctl compute size list                        # All sizes
doctl compute size list --output json | jq '.[] | select(.slug | startswith("gpu-mi"))'  # AMD GPUs only
doctl compute image list --public              # Available images
```

### Monitoring

```bash
doctl compute droplet actions <id>             # Action history
doctl monitoring alert list                    # Alerts
```

### Tags (useful for batch operations)

```bash
doctl compute droplet tag <id> --tag-name training-batch-1
doctl compute droplet list --tag-name training-batch-1
doctl compute droplet delete --tag-name training-batch-1 --force  # Kill batch
```

## A. CLI and YAML-Only Configuration

Our training CLI is `python -m ptbr` with three subcommands:

```bash
python -m ptbr data       # Load, validate, prepare datasets
python -m ptbr config     # Validate YAML config (no training)
python -m ptbr train      # Validate + launch training
```

**ALWAYS use YAML configuration files.** Never pass training parameters as CLI flags or
hardcode them in scripts. The CLI validates 90+ fields with type checking, enum validation,
cross-field semantic checks, data path verification, and API connectivity tests.

Key training CLI usage:

```bash
# Validate only (fast, no GPU needed)
python -m ptbr.training_cli --validate configs/my_config.yaml

# Launch training with output folder
python -m ptbr.training_cli --output-folder ./runs/my_run configs/my_config.yaml

# Resume from checkpoint
python -m ptbr.training_cli --output-folder ./runs/my_run --resume configs/my_config.yaml
```

The base model we finetune is `urchade/gliner_multi-v2.1` (backbone: `microsoft/mdeberta-v3-base`).
See `{baseDir}/references/gliner_config.json` for the upstream model's default config values.

When creating new configs, start from an existing one in `configs/` or `training_feb_22/config/`
and modify. The YAML structure has sections: `run`, `model`, `data`, `training`, `lora`, `environment`.

## B. Environment Variables

Environment variables live at `~/.env/.env`. The CLI auto-loads them via `python-dotenv`.

Required variables:

```bash
# ~/.env/.env
HF_TOKEN=hf_xxxxxxxxxxxxxxxxxxxx
WANDB_API_KEY=xxxxxxxxxxxxxxxxxxxxxxxx
```

Before any training run, verify these are set:

```bash
source ~/.env/.env
echo "HF_TOKEN set: $([ -n \"$HF_TOKEN\" ] && echo yes || echo NO)"
echo "WANDB_API_KEY set: $([ -n \"$WANDB_API_KEY\" ] && echo yes || echo NO)"
```

On remote droplets, copy the env file:

```bash
scp ~/.env/.env root@<droplet-ip>:~/.env/.env
```

## C. Maximize GPU Utilization

NEVER leave GPU idle. Two strategies:

### Strategy 1: Increase batch size until OOM

Start with the config's `train_batch_size`, double it, and test:

```bash
# Test with validation-only to catch OOM early
python -m ptbr.training_cli --validate configs/my_config.yaml
# Then launch -- if OOM, halve the batch size
```

For `gpu-mi300x1-192gb` (192GB VRAM) with mdeberta-v3-base:
- Full fine-tune: start at `train_batch_size: 32`, try up to 64
- LoRA: start at `train_batch_size: 64`, try up to 128
- Use `gradient_accumulation_steps` to simulate larger effective batches

### Strategy 2: Run multiple trainings in parallel

With 192GB GPU memory, run multiple small trainings on different CUDA devices or
use different GPU fractions:

```yaml
# Config A: uses GPU 0
environment:
  cuda_visible_devices: "0"

# Config B: on an 8-GPU machine, uses GPU 1
environment:
  cuda_visible_devices: "1"
```

On 8-GPU machines (`gpu-mi300x8-1536gb`), launch up to 8 independent runs.
Use `tmux` sessions for each:

```bash
tmux new-session -d -s train_a "CUDA_VISIBLE_DEVICES=0 python -m ptbr.training_cli --output-folder ./runs/a configs/a.yaml"
tmux new-session -d -s train_b "CUDA_VISIBLE_DEVICES=1 python -m ptbr.training_cli --output-folder ./runs/b configs/b.yaml"
```

Also enable these for memory efficiency:
- `training.gradient_checkpointing: true` (trades compute for memory)
- `training.bf16: true` (half-precision on AMD MI300X/MI325X/MI350X)
- `training.compile_model: true` (torch.compile optimization)

## D. Remote GPU Droplet Management

This skill manages training on DigitalOcean GPU droplets via `doctl`.

**WE CAN ONLY USE AMD MOTHERBOARDS. THIS IS NON-NEGOTIABLE.**

### Create a droplet

```bash
doctl compute droplet create gliner-train-$(date +%Y%m%d) \
  --size gpu-mi300x1-192gb \
  --image <amd-gpu-base-image> \
  --region <region> \
  --ssh-keys <key-fingerprint> \
  --tag-names gpu,gliner-training \
  --wait

# Save droplet ID for the monitoring hook
DROPLET_ID=$(doctl compute droplet list --format ID,Name --no-header | grep gliner-train | awk '{print $1}')
echo "$DROPLET_ID" > /tmp/gliner_droplet_id
```

### Monitor

```bash
bash {baseDir}/scripts/check_training.sh <droplet-id>
```

### When training completes

Follow **PRIORITY #1** above: upload artifacts via the waterfall (HF -> Spaces -> SCP),
then DESTROY the droplet immediately.

## E. Package Installation on Remote Machines

Use `uv` as the package manager. The install sequence matters because torch and flash
attention require special download sources.

### Step 1: Install uv

```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
source $HOME/.local/bin/env
```

### Step 2: Create venv and install torch FIRST (special link required)

```bash
uv venv .venv --python 3.11
source .venv/bin/activate

# AMD ROCm torch (for AMD GPUs -- THIS IS WHAT WE USE)
uv pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/rocm6.2

# Verify torch sees the GPU
python -c "import torch; print(f'CUDA available: {torch.cuda.is_available()}'); print(f'Device: {torch.cuda.get_device_name(0) if torch.cuda.is_available() else \"none\"}')"
```

### Step 3: Install flash attention (special build required)

```bash
# FlashDeBERTa for DeBERTa-based GLiNER models
uv pip install flashdeberta -U

# Verify
python -c "import flashdeberta; print('FlashDeBERTa OK')"
```

Enable in environment:

```bash
export USE_FLASHDEBERTA=1
```

### Step 4: Install GLiNER from our package

```bash
cd /root/workspace/training_gliner
uv pip install -e ".[training]"

# Also install optional deps
uv pip install peft python-dotenv requests wandb
```

### Step 5: Verify full stack

```bash
python -c "
import torch
import transformers
from gliner import GLiNER
print(f'torch: {torch.__version__}')
print(f'transformers: {transformers.__version__}')
print(f'CUDA: {torch.cuda.is_available()}')
print(f'Device: {torch.cuda.get_device_name(0) if torch.cuda.is_available() else \"N/A\"}')
print('GLiNER import OK')
"
```

### Full one-liner setup for a fresh droplet

```bash
curl -LsSf https://astral.sh/uv/install.sh | sh && \
source $HOME/.local/bin/env && \
uv venv .venv --python 3.11 && \
source .venv/bin/activate && \
uv pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/rocm6.2 && \
uv pip install flashdeberta -U && \
cd /root/workspace/training_gliner && \
uv pip install -e ".[training]" && \
uv pip install peft python-dotenv requests wandb && \
python -c "import torch; from gliner import GLiNER; print(f'Ready. CUDA: {torch.cuda.is_available()}')"
```

<!-- cross-ref:start -->

## See also (related skills — GLiNER family)

If your issue relates to:
- **ML training strategy for GLiNER fine-tuning** — check `ml-training-gliner` if appropriate.
- **CUDA / ONNX Runtime / PyTorch on remote GPU servers** — check `cuda-remote-setup` if appropriate.

<!-- cross-ref:end -->


---

# CUDA / ONNX / PyTorch on remote GPU

_Merged from former `cuda-remote-setup` skill — generic GPU setup for ONNX Runtime, PyTorch, and any CUDA-dependent inference on remote servers (Vast.ai, Lambda, RunPod, DigitalOcean). Read this BEFORE provisioning a droplet in the GLiNER training pipeline._


# CUDA Remote Server Setup — Never Assume, Always Verify

## Overview

Remote GPU servers lie. `nvidia-smi` shows a GPU, the driver says CUDA 13.0, but your model runs on CPU at 1.5 samples/sec instead of 50. This skill ensures CUDA actually works before you waste hours on CPU inference.

## The Iron Rule

**After every model load on a remote server, check GPU memory. If it's under 100 MiB, CUDA is not working. Stop and fix before running inference.**

```bash
nvidia-smi --query-gpu=memory.used --format=csv,noheader
# If this says "2 MiB" after loading a model — you're on CPU.
# If this says "1950 MiB" or more — CUDA is working.
```

## The Verification Sequence

Run these in order. Do not skip steps. Do not assume.

### 1. Check driver vs toolkit vs runtime

```bash
# Driver CUDA version (what the GPU supports)
nvidia-smi | grep "CUDA Version"

# Toolkit version (what nvcc compiles against)
nvcc --version | grep release    # Often missing on containers!

# Runtime libraries actually present
ldconfig -p | grep libcudart
```

**Pitfall**: Driver CUDA 13.0 does NOT mean you have CUDA 13.0 toolkit. Drivers are backward-compatible. The toolkit version matters.

### 2. Check ALL library dependencies

For ONNX Runtime GPU:
```bash
ldd /path/to/libonnxruntime_providers_cuda.so | grep "not found"
```

**If ANYTHING says "not found", CUDA will silently fall back to CPU.** No error, no warning, just slow inference.

### 3. The Missing Libraries (real examples)

ORT 1.20.1 on a Vast.ai pytorch/pytorch:latest image was missing:

| Library | What it is | Where we found it |
|---------|-----------|-------------------|
| `libcudnn.so.9` | cuDNN 9 (NOT 8!) | `apt install libcudnn9-cuda-12` |
| `libcublas.so.12` | cuBLAS | `/opt/conda/lib/` (symlink needed) |
| `libcublasLt.so.12` | cuBLAS Lt | `/opt/conda/lib/` (symlink needed) |
| `libcurand.so.10` | cuRAND | `/opt/conda/lib/` (symlink needed) |
| `libcufft.so.11` | cuFFT | `/opt/conda/lib/` (symlink needed) |
| `libnvrtc.so.12` | NVRTC | `/opt/conda/lib/` (symlink needed) |

**Pitfall**: PyTorch bundles cuDNN 8. ORT 1.20.1 needs cuDNN 9. They coexist but you must install cuDNN 9 separately.

### 4. Fix missing libraries

```bash
# Option A: Install from NVIDIA repo
wget -q https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/cuda-keyring_1.1-1_all.deb
dpkg -i cuda-keyring_1.1-1_all.deb
apt-get update -qq
apt-get install -y libcudnn9-cuda-12 libcublas-12-6 libnvrtc-12-6 libcurand-12-6 libcufft-12-6

# Option B: Symlink from conda (if libs exist there)
for lib in libcublas.so.12 libcublasLt.so.12 libcurand.so.10 libcufft.so.11 libnvrtc.so.12; do
    src=$(find /opt/conda/lib -maxdepth 1 -name "$lib" | head -1)
    [ -n "$src" ] && ln -sf "$src" /usr/lib/x86_64-linux-gnu/$lib
done
ldconfig
```

### 5. Verify zero missing, then test

```bash
# Must show ZERO "not found"
ldd /path/to/libonnxruntime_providers_cuda.so | grep "not found"

# Run inference and check GPU memory DURING execution
your_binary --input test.jsonl &
sleep 15
nvidia-smi --query-gpu=memory.used --format=csv,noheader
# Must be >> 100 MiB
```

## Pitfalls We Hit (Real Session)

### 1. Silent CPU fallback
ORT registers CUDA EP but if any library is missing, it silently falls back to CPU. No error message. Model loads, inference runs, just 17x slower. The only way to detect this is checking GPU memory.

### 2. apt-get lock contention
Multiple apt installs on the same server fight for dpkg locks. Kill stale processes:
```bash
kill $(fuser /var/lib/dpkg/lock-frontend 2>/dev/null)
rm -f /var/lib/dpkg/lock-frontend /var/lib/dpkg/lock
dpkg --configure -a
```

### 3. cuDNN version mismatch
PyTorch ships cuDNN 8 in `/opt/conda/lib/python3.10/site-packages/torch/lib/libcudnn.so.8`. ORT 1.20.1 needs cuDNN 9 (`libcudnn.so.9`). Both can coexist — install cuDNN 9 system-wide, leave PyTorch's cuDNN 8 alone.

### 4. First inference is slow with CUDA
CUDA JIT-compiles kernels on first run. A single sample can take 2-3 minutes. This is normal. Subsequent samples are fast. Don't kill the process thinking it's hung.

### 5. Compiling Rust on the server
The pytorch:latest image has no `cc`/`gcc`. Install before cargo build:
```bash
apt-get install -y build-essential pkg-config libssl-dev
```

### 6. nvcc not found
The pytorch image has CUDA runtime but not the compiler. Install separately:
```bash
apt-get install -y cuda-nvcc-12-6
export PATH=/usr/local/cuda-12.6/bin:$PATH
```

### 7. Sending bloated tarballs
`tar` without `--exclude='target'` sends gigabytes of compiled binaries. Always:
```bash
tar czf source.tar.gz --exclude='target' --exclude='.git' --exclude='eval_predictions' .
```

### 8. RTX 5060 Ti / Blackwell architecture
Newer GPUs (RTX 50xx) need driver 580+. ORT 1.20.1 works with CUDA 12.x on these GPUs but the first model load takes ~11s (vs ~4s on older GPUs) due to kernel compilation.

## Quick Checklist

```
[ ] nvidia-smi shows GPU
[ ] ldd libonnxruntime_providers_cuda.so — ZERO "not found"
[ ] Model loaded — nvidia-smi shows >> 100 MiB GPU memory
[ ] First sample completed (may take minutes for JIT)
[ ] Subsequent samples running at expected speed (>> 10 samples/sec for small models)
```

## Red Flags — STOP and Debug

- `CUDA EP registered: false` — binary not compiled with `--features=cuda`
- GPU memory stays at "2 MiB" after model load — CUDA fallback to CPU
- "not found" in ldd output — missing library, will silently use CPU
- 1-3 samples/sec on a dedicated GPU — you're on CPU
- Model loads in 3-4s instead of 10-12s — CPU load, not GPU (GPU takes longer due to CUDA init)

<!-- cross-ref:start -->

## See also (related skills — GLiNER family)

If your issue relates to:
- **GLiNER training ops on remote AMD GPU droplets** — check `gliner-training-admin` if appropriate.
- **ML training strategy for GLiNER fine-tuning** — check `ml-training-gliner` if appropriate.

<!-- cross-ref:end -->

