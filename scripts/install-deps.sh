#!/usr/bin/env bash
set -euo pipefail

WITH_ORACLE=0
if [[ "${1:-}" == "--oracle" ]]; then
    WITH_ORACLE=1
elif [[ $# -gt 0 ]]; then
    echo "Usage: $0 [--oracle]" >&2
    exit 2
fi

have() { command -v "$1" >/dev/null 2>&1; }

if have apt-get; then
    echo "[fedra-modern-linux] Debian/Ubuntu family detected"
    sudo apt-get update

    base=(
        build-essential git wget curl python3 python3-pip unzip
        libx11-6 libxpm4 libxft2 libxext6
        libgl-dev libglu1-mesa-dev
    )

    sudo apt-get install -y "${base[@]}"

    # Package names vary slightly between Debian/Ubuntu releases.
    for pkg in libftgl2 libgl2ps1.4 libgif7 libtbb12; do
        if apt-cache show "$pkg" >/dev/null 2>&1; then
            sudo apt-get install -y "$pkg"
        else
            echo "[warn] Package not found in this release: $pkg"
        fi
    done

    if (( WITH_ORACLE )); then
        if apt-cache show libaio1t64 >/dev/null 2>&1; then
            sudo apt-get install -y libaio1t64
        elif apt-cache show libaio1 >/dev/null 2>&1; then
            sudo apt-get install -y libaio1
        else
            echo "[warn] Could not find libaio1t64/libaio1 automatically."
        fi
    fi

elif have pacman; then
    echo "[fedra-modern-linux] Arch Linux detected"
    sudo pacman -Syu --needed --noconfirm \
        base-devel git wget curl python python-pip unzip \
        libx11 libxpm libxft libxext \
        mesa glu ftgl gl2ps giflib tbb openssl

    if (( WITH_ORACLE )); then
        echo "[note] Oracle Instant Client is not installed by this script."
        echo "[note] Install Oracle's prerequisites/Instant Client separately."
    fi

elif have dnf; then
    echo "[fedra-modern-linux] Fedora detected"
    sudo dnf install -y \
        gcc gcc-c++ make git wget curl python3 python3-pip unzip \
        libX11 libXpm libXft libXext \
        mesa-libGL-devel mesa-libGLU-devel \
        ftgl gl2ps giflib tbb openssl

    if (( WITH_ORACLE )); then
        sudo dnf install -y libaio || true
        echo "[note] Oracle Instant Client itself is not installed by this script."
    fi

else
    echo "Unsupported package manager." >&2
    echo "Install a C++ build toolchain, Python 3, ROOT runtime dependencies, OpenGL/GLU, FTGL, gl2ps and giflib manually." >&2
    exit 1
fi

echo "[fedra-modern-linux] System dependencies installed."
echo "[fedra-modern-linux] ROOT and FEDRA are intentionally installed separately."
