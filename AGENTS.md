# Agent Instructions

This repository is the source of truth for personal dotfiles, package bootstrap scripts, the global Codex instruction mirror, and shared skills. Keep changes scoped; inspect tracked and live copies before changing mirrored assets.

## Sync boundaries

- `bootstrap.sh` syncs the repository into `$HOME`, excluding `.git/`, `.github/`, `.agents/`, `.codex/skills/`, `dockerfiles/`, `bootstrap.sh`, `pacman.sh`, `brew.sh`, `Brewfile`, `README.md`, root `/AGENTS.md`, `LICENSE-MIT.txt`, and `.DS_Store`.
- `.codex/AGENTS.md` is included in the main sync and mirrors `~/.codex/AGENTS.md`.
- `.codex/skills/` is synced separately: tracked files overwrite or add files; local-only files remain unless `--delete-skills` is used. That mode still excludes `.system/` and `codex-primary-runtime/`.
- `.docker/daemon.json` is the global Docker configuration. `dockerfiles/` is repository-only and is not copied to `$HOME`.

## Source of truth

| Concern | Source |
| --- | --- |
| macOS packages | `Brewfile`; required taps stay in `brew.sh` |
| Arch packages | `pacman.sh` `packages` array |
| Dotfile sync | `bootstrap.sh` |
| Global Codex instructions | `.codex/AGENTS.md` ↔ `~/.codex/AGENTS.md` |
| Shared skills | `.codex/skills/` ↔ `~/.codex/skills/` |
| Docker daemon | `.docker/daemon.json` |
| Docker images | `dockerfiles/<image>/Dockerfile` and its README |

## Commands

| Task | Command |
| --- | --- |
| Preview sync | `bash ./bootstrap.sh --dry-run` |
| Apply sync with backup | `bash ./bootstrap.sh --force --backup` |
| Check/preview Homebrew | `brew bundle check --no-upgrade --file Brewfile`; `bash ./brew.sh --dry-run` |
| Shell checks | `bash -n bootstrap.sh brew.sh pacman.sh`; `shellcheck bootstrap.sh brew.sh pacman.sh`; `shfmt -d -i 4 -ci bootstrap.sh brew.sh pacman.sh` |
| Build cross-compile image | `docker build -t cross-compile-builder ./dockerfiles/cross-compile-builder/` |
| Smoke-test image | `docker run --rm cross-compile-builder go version` |

## Workflows

### Package lists

- Keep only manually selected formulae/casks in `Brewfile`; compare formulae with `brew leaves` and casks with `brew list --cask`.
- Add a cask's required tap to `brew.sh`, then run the Homebrew check above.
- Treat `pacman.sh`'s `packages` array as the direct Arch install list.

### Mirrored Codex assets

- Edit tracked copies under `.codex/`, preview with `--dry-run`, apply with `bash ./bootstrap.sh --force`, then verify with `cmp` or an rsync checksum comparison.
- Keep each skill self-contained: update its `SKILL.md` and referenced scripts, templates, references, notices, or licenses together.
- Do not use `--delete-skills` to remove local-only or system skills without explicit authorization.

### Docker

- Edit the relevant `Dockerfile` directly. For `cross-compile-builder`, `GO_VERSION` defaults to `latest`, `BASE_IMAGE` to `debian:bookworm-slim`, and `IMAGE_PLATFORM` to `linux/amd64`; the Linaro toolchains require an x86_64 build platform.
- After Docker daemon changes, apply the synced config, restart Docker Desktop, and verify mirrors with `docker info --format '{{.RegistryConfig.Mirrors}}'`.

## Verification

- Run the relevant command above after changing packages, sync boundaries, mirrored assets, or Docker files.
- CI checks only `bootstrap.sh`, `brew.sh`, and `pacman.sh`; update `.github/workflows/shell-checks.yml` when adding another maintained root shell script.
- A local syntax/build check does not prove target-device, external-service, or production behavior.

## Pitfalls

- Root `AGENTS.md` is excluded from sync; edit `.codex/AGENTS.md` for global Codex instructions.
- `brew list --formula` includes dependencies; use `brew leaves` when maintaining `Brewfile`.
- `--delete-skills` is the only mirror-cleanup mode and still protects `.system/` and `codex-primary-runtime/`.
- Do not change the cross-compile image platform without replacing the x86_64-only Linaro toolchains.

## Maintenance

Update this file when the sync boundary, package workflow, skill-sync model, Docker workflow, or verification commands change.
