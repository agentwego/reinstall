# Local KVM Test Harness

This directory contains local-only tooling for iterating on `reinstall.sh` in KVM without adding extra production CLI flags.

The default workflow is:

1. Serve the repository root over HTTP as a temporary `confhome`.
2. Patch local `confhome` constants in [`reinstall.sh`](/home/yun/Desktop/reinstall/reinstall.sh) and [`trans.sh`](/home/yun/Desktop/reinstall/trans.sh).
3. Boot a local VM with QEMU/KVM.
4. Restore the original files after the test.

By default the patch script uses `http://10.0.2.2:8000` as `confhome`. That address is reachable from guests when QEMU uses user-mode networking.

## Layout

- `Taskfile.yml`: common local test tasks.
- `scripts/`: helper scripts for patching, restoring, serving, and launching QEMU.
- `kvm/common.env`: shared QEMU defaults.
- `kvm/talos.env`: Talos-focused VM profile.
- `kvm/talos.local.env.example`: copy to `talos.local.env` for machine-specific overrides.

## Prerequisites

- `python3`
- `qemu-system-x86_64`
- `qemu-img`
- `/dev/kvm` access if you want hardware acceleration
- A bootable guest image or ISO

## Quick Start

Serve the repo root:

```bash
cd test
task serve
```

Patch `confhome` to the host-side HTTP server:

```bash
cd test
task patch-confhome
```

Prepare local overrides:

```bash
cd test/kvm
cp talos.local.env.example talos.local.env
```

Then edit `talos.local.env` and set at least one of:

- `BASE_IMAGE=/absolute/path/to/base-image.qcow2`
- `BOOT_ISO=/absolute/path/to/installer.iso`
- `DISK_IMAGE=/absolute/path/to/existing-disk.qcow2`

Run the Talos test VM:

```bash
cd test
task talos
```

Restore patched files after the test:

```bash
cd test
task restore-confhome
```

## Notes

- `task talos` does not auto-restore patched files. That is intentional, so you can reboot or rerun the VM quickly while iterating.
- If you use bridged networking instead of QEMU user networking, override `CONFHOME_URL` or `HOST_IP` when patching.
- Generated images and logs live under `test/state/` and `test/artifacts/`.
