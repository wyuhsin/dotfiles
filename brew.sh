#!/usr/bin/env bash
set -euo pipefail

BREWFILE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/Brewfile"
DRY_RUN=false
UPGRADE=false
UPDATE=false
CLEANUP=true

# This repository is authoritative for non-core Homebrew taps.
required_taps=()

protected_taps=(
    homebrew/core
    homebrew/cask
    homebrew/bundle
)

usage() {
    cat <<'USAGE'
Usage: brew.sh [--upgrade] [--update] [--dry-run] [--no-cleanup]

Install Homebrew packages declared in Brewfile.

Synchronize Homebrew taps to the required_taps list. Taps not declared by this
repository are removed, together with formulae and casks installed from them.
Formulae and casks not declared by this repository are also removed by default.

Options:
  -u, --upgrade   Upgrade already installed packages
  --update        Update Homebrew metadata before installing packages
  -n, --dry-run   Show actions without installing or upgrading packages
  --no-cleanup    Keep formulae and casks not declared in Brewfile
  -h, --help      Show this help
USAGE
}

while (($#)); do
    case "$1" in
        -u | --upgrade)
            UPGRADE=true
            ;;
        --update)
            UPDATE=true
            ;;
        --no-cleanup)
            CLEANUP=false
            ;;
        -n | --dry-run)
            DRY_RUN=true
            ;;
        -h | --help)
            usage
            exit 0
            ;;
        *)
            echo "unknown option: $1" >&2
            usage >&2
            exit 1
            ;;
    esac
    shift
done

if ! command -v brew >/dev/null 2>&1; then
    if [[ "$DRY_RUN" == true ]]; then
        echo "would install Homebrew"
        exit 0
    fi

    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

BREW_BIN="$(command -v brew || true)"
if [[ -z "$BREW_BIN" ]]; then
    if [[ -x /opt/homebrew/bin/brew ]]; then
        BREW_BIN="/opt/homebrew/bin/brew"
    elif [[ -x /usr/local/bin/brew ]]; then
        BREW_BIN="/usr/local/bin/brew"
    else
        echo "brew installed but executable not found in PATH" >&2
        exit 1
    fi
fi

eval "$("$BREW_BIN" shellenv)"

if [[ "$UPDATE" == false ]]; then
    export HOMEBREW_NO_AUTO_UPDATE=1
fi

tap_is_listed() {
    local tap candidate
    tap="$1"

    if ((${#required_taps[@]} > 0)); then
        for candidate in "${required_taps[@]}"; do
            if [[ "$candidate" == "$tap" ]]; then
                return 0
            fi
        done
    fi

    for candidate in "${protected_taps[@]}"; do
        if [[ "$candidate" == "$tap" ]]; then
            return 0
        fi
    done

    return 1
}

sync_taps() {
    local tap

    if ((${#required_taps[@]} > 0)); then
        for tap in "${required_taps[@]}"; do
            if ! "$BREW_BIN" tap | grep -Fxq "$tap"; then
                if [[ "$DRY_RUN" == true ]]; then
                    echo "would run: brew tap $tap"
                else
                    "$BREW_BIN" tap "$tap"
                fi
            fi
        done
    fi

    while IFS= read -r tap; do
        [[ -z "$tap" ]] && continue
        if tap_is_listed "$tap"; then
            continue
        fi

        if [[ "$DRY_RUN" == true ]]; then
            echo "would run: brew untap --force $tap"
        else
            "$BREW_BIN" untap --force "$tap"
        fi
    done < <("$BREW_BIN" tap)
}

cleanup_packages() {
    # Homebrew's bundle cleanup keeps the recursive formula dependencies of
    # every formula and cask declared in Brewfile. Only unlisted, unused
    # formulae/casks are candidates for removal.
    local -a cleanup_args=(
        bundle
        cleanup
        --formula
        --cask
        --no-tap
        --file
        "$BREWFILE"
    )

    [[ "$CLEANUP" == true ]] || return 0

    if [[ "$DRY_RUN" == true ]]; then
        "$BREW_BIN" "${cleanup_args[@]}" </dev/null || true
    else
        "$BREW_BIN" "${cleanup_args[@]}" --force
    fi
}

if [[ "$DRY_RUN" == true ]]; then
    if [[ "$UPDATE" == true ]]; then
        echo "would run: brew update"
    fi
    sync_taps
    "$BREW_BIN" bundle check --file "$BREWFILE" || true
    cleanup_packages
    if [[ "$UPGRADE" == true ]]; then
        echo "would run: brew bundle install --upgrade --file $BREWFILE"
    else
        echo "would run: brew bundle install --no-upgrade --file $BREWFILE"
    fi
else
    if [[ "$UPDATE" == true ]]; then
        "$BREW_BIN" update
    fi

    sync_taps

    install_status=0
    if [[ "$UPGRADE" == true ]]; then
        "$BREW_BIN" bundle install --upgrade --file "$BREWFILE" || install_status=$?
    else
        "$BREW_BIN" bundle install --no-upgrade --file "$BREWFILE" || install_status=$?
    fi

    cleanup_status=0
    cleanup_packages || cleanup_status=$?

    if ((install_status != 0)); then
        exit "$install_status"
    fi
    exit "$cleanup_status"
fi
