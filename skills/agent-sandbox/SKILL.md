---
name: agent-sandbox
description: Kernel-enforced (landlock) capability-based sandbox for running AI agents and untrusted code via nono — restrict filesystem, block network, inject credentials, take rollback snapshots, audit trails. Use for sandboxing agents, blocking destructive commands, running untrusted code safely.
---

# agent-sandbox — Kernel-Enforced Sandbox for AI Agents (nono)

Use this skill when you need to run commands or agents in a secure, capability-based sandbox using nono. Applies to: sandboxing AI agents, restricting filesystem access, blocking network, blocking destructive commands, credential injection, rollback snapshots, audit trails, and running untrusted code safely. Triggers on: "sandbox", "nono", "secure execution", "isolate agent", "restrict access", "block network", "capability sandbox", "landlock", "run safely", "agent security".

---

## Installation & Binary Locations

| Component | Path |
|-----------|------|
| CLI binary | `~/.local/bin/nono` |
| Source repo | `/home/arthrod/workspace/tmp/multiple_claws/nono` |
| Built-in profiles | embedded in binary + `~/.config/nono/profiles/` |

**Quick check:**

```bash
nono --version   # 0.10.0
```

---

## Core Concepts

- **nono** is a kernel-enforced sandbox — uses **Landlock** (Linux 5.13+) or **Seatbelt** (macOS).
- **No root, no daemon, no VM** — pure syscall-level restrictions.
- Permissions are **capability-based**: you explicitly allow paths; everything else is denied.
- Once applied, the sandbox is **irreversible** — cannot be escaped or escalated.
- Child processes inherit the same restrictions.
- Destructive commands (`rm`, `dd`, `chmod`, `sudo`, `scp`) are blocked by default.
- Network is allowed by default; use `--net-block` to deny it.

---

## Quick Reference: CLI

### 1. Basic Sandbox — Read-only access

```bash
# Read-only access to ./src, deny everything else
nono run --read ./src -- cat ./src/main.rs

# Silent mode (no banner)
nono run -s --allow-cwd --read ./data -- python3 process.py
```

### 2. Read + Write access

```bash
# Read src, write to output directory
nono run --read ./src --write ./output -- cargo build

# Full read+write to a directory
nono run --allow ./project -- cargo build
```

### 3. Allow current working directory

```bash
# --allow-cwd grants access to CWD (required in silent/non-interactive mode)
nono run -s --allow-cwd -- ls -la
```

### 4. Block network

```bash
# Build with no network access
nono run --allow-cwd --net-block -- cargo build
```

### 5. Block destructive commands

```bash
# rm is blocked by default
nono run --allow /tmp -- rm -rf /tmp/data
# ERROR: Command 'rm' is blocked

# Override if you really need it
nono run --allow /tmp --allow-command rm -- rm /tmp/test.txt
```

### 6. Network filtering (proxy allowlist)

```bash
# Only allow specific hosts
nono run --allow-cwd --network-profile claude-code \
  --proxy-allow api.openai.com --proxy-allow api.anthropic.com -- my-agent
```

### 7. Credential injection

```bash
# Proxy mode — agent never sees the API key
nono run --network-profile claude-code --proxy-credential openai -- my-agent

# Env mode — load from system keyring
nono run --allow-cwd --env-credential openai_api_key,anthropic_api_key -- my-agent

# 1Password
nono run --allow-cwd --env-credential 'op://vault/item/field=OPENAI_API_KEY' -- my-agent
```

### 8. Named profiles

```bash
# Built-in profiles for AI agents
nono run --profile claude-code -- claude
nono run --profile opencode -- opencode
nono run --profile openclaw -- openclaw gateway

# Profile + extra permissions
nono run --profile claude-code --read /tmp/extra -- claude
```

### 9. Rollback snapshots

```bash
# Enable atomic rollback — snapshot before execution
nono run --rollback --allow-cwd -- claude

# List and restore rollback sessions
nono rollback list
nono rollback restore
```

### 10. Audit trail

```bash
# List past sessions
nono audit list

# Show details of a session
nono audit show <SESSION_ID> --json
```

### 11. Dry run

```bash
# See what would be sandboxed without executing
nono run --dry-run --read ./src --write ./out -- cargo build
```

### 12. Why command — check permission reasoning

```bash
nono why --read /tmp --write /tmp/out
```

### 13. Supervised mode — capability expansion with approval

```bash
# Parent stays unsandboxed to approve additional access requests
nono run --supervised --rollback --allow-cwd -- claude
```

### 14. Port binding inside sandbox

```bash
# Allow the sandboxed process to listen on a port
nono run --allow-cwd --allow-bind 8080 -- python3 -m http.server 8080
```

---

## Rust Library API

The core library (`nono` crate) is a policy-free sandbox primitive:

```rust
use nono::{CapabilitySet, AccessMode, Sandbox};

fn main() -> nono::Result<()> {
    let caps = CapabilitySet::new()
        .allow_path("/data/models", AccessMode::Read)?
        .allow_path("/tmp/workspace", AccessMode::ReadWrite)?
        .block_network();

    // Check platform support
    let support = Sandbox::support_info();
    if !support.is_supported {
        eprintln!("Warning: {}", support.details);
    }

    // Apply — irreversible from here on
    Sandbox::apply(&caps)?;

    Ok(())
}
```

---

## Key Flags Reference

| Flag | Purpose |
|------|---------|
| `--read <DIR>` | Read-only access to directory (recursive) |
| `--write <DIR>` | Write-only access to directory |
| `--allow <DIR>` | Read+write access to directory |
| `--read-file <F>` | Read-only access to single file |
| `--write-file <F>` | Write-only access to single file |
| `--allow-cwd` | Allow access to current working directory |
| `--net-block` | Block all network access |
| `--network-profile <P>` | Proxy-based host allowlist |
| `--proxy-credential <S>` | Inject credentials via proxy (agent never sees key) |
| `--env-credential <C>` | Inject credentials as env vars |
| `--allow-bind <PORT>` | Allow binding a TCP port |
| `--allow-command <CMD>` | Override a blocked destructive command |
| `--block-command <CMD>` | Block an additional command |
| `--rollback` | Enable atomic rollback snapshots |
| `--supervised` | Supervised mode for capability expansion |
| `--dry-run` | Show sandbox config without executing |
| `--exec` | Preserve TTY for interactive apps |
| `--profile <NAME>` | Use a named security profile |
| `-s, --silent` | Suppress nono banner/output |
| `-v, --verbose` | Show detailed capability listing |

---

## Bundled Examples

All examples are in `~/.agents/skills/nono/examples/`:

| File | What it demonstrates |
|------|---------------------|
| `01_sandbox_basics.sh` | Read-only, read-write, write denied, outside-sandbox denied |
| `02_network_and_commands.sh` | Network blocking, destructive command blocking |
| `03_deploy_in_sandbox.sh` | Deploy a Rust service inside a nono sandbox with port binding |

**Run any example:**

```bash
bash ~/.agents/skills/nono/examples/01_sandbox_basics.sh
```

---

## Platform Support

| Platform | Mechanism | Minimum |
|----------|-----------|---------|
| Linux | Landlock | Kernel 5.13+ |
| macOS | Seatbelt | 10.5+ |

No root, no `CAP_SYS_ADMIN`, no daemon. Works in Docker, Podman, K8s, Firecracker, Kata, and bare metal.

---

## Troubleshooting

| Problem | Fix |
|---------|-----|
| `CWD access requires --allow-cwd` | Add `--allow-cwd` flag (required in silent/non-interactive mode) |
| `Permission denied` on expected path | Verify path is granted via `--read`, `--write`, or `--allow` |
| Command blocked | Use `--allow-command <cmd>` to override (use with caution) |
| Landlock not available | Check kernel ≥ 5.13: `uname -r` |
| Need verbose output | Add `-v` to see all granted capabilities |

---

## Build from Source

```bash
cd /home/arthrod/workspace/tmp/multiple_claws/nono
sudo apt install libdbus-1-dev pkg-config  # if needed
cargo build --release
cp target/release/nono ~/.local/bin/nono
```
