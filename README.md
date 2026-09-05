# FEDRA Modern Linux

Compatibility helpers and installation scripts for building **OPERA FEDRA** on modern Linux distributions with recent ROOT/GCC toolchains.

This repository **does not redistribute FEDRA, ROOT, Oracle Instant Client, OPERA data, or third-party binaries**. It patches a FEDRA source tree that you obtain separately.

## Status

Tested end-to-end:

- Debian 13 (Trixie)
- ROOT 6.40.04
- GCC 14.2
- x86_64
- FEDRA core applications, EDA, reconstruction, vertexing, and optional Oracle/OCCI applications

Installer dependency mappings are also provided for:

- Arch Linux
- Ubuntu / Debian-family systems
- Fedora

Those distributions should be considered **best-effort until independently tested**.

## What this fixes

The compatibility layer includes fixes for issues encountered with older FEDRA sources on modern toolchains:

- missing `TMath.h` includes
- removed ROOT `gErrorMutex` usage
- old `TF1` member-function constructor syntax
- removed `TGLIncludes.h`
- ROOT 6 dictionary / `rootcling` handling for `libDataConversion`
- GCC 14 narrowing errors in `comptonmap`
- modern linker `--as-needed` behavior
- FEDRA shared-library dependencies
- ROOT PCM dictionary placement
- stale application targets such as `emrawcorr` when the corresponding source is absent
- optional Oracle/OCCI build support through `OCCIHOME`

## 1. Obtain FEDRA

Obtain the original FEDRA source separately.

A published FEDRA archive is available through Zenodo:

- DOI: `10.5281/zenodo.4390588`

Extract it somewhere convenient, for example:

```bash
mkdir -p ~/fedra-work
# extract FEDRA so that the source root contains install.sh and src/
export FEDRA_ROOT=~/fedra-work/fedra
```

## 2. Install Linux dependencies

Clone this compatibility repository and run:

```bash
./scripts/install-deps.sh
```

The script detects `apt`, `pacman`, or `dnf`.

Oracle dependencies are optional:

```bash
./scripts/install-deps.sh --oracle
```

This installs only system prerequisites. It does **not** download Oracle Instant Client.

## 3. Install / activate ROOT

Use a recent ROOT installation compatible with your compiler.

The configuration tested for this project is ROOT 6.40.04.

Example:

```bash
source ~/root/bin/thisroot.sh
root-config --version
```

The ROOT project publishes binary builds for multiple Linux distributions. Prefer a binary built for your distribution/toolchain when possible.

## 4. Patch FEDRA

```bash
python3 scripts/patch-fedra.py "$FEDRA_ROOT"
```

The patcher is designed to be idempotent: running it more than once should not duplicate includes or rules.

## 5. Build FEDRA

```bash
./scripts/build-fedra.sh "$FEDRA_ROOT"
```

Then check:

```bash
./scripts/check-fedra.sh "$FEDRA_ROOT"
```

If Oracle Instant Client is not configured, `o2root`, `fb2db`, and `scan2db` may remain unavailable while the normal FEDRA reconstruction/EDA stack still works.

## 6. Environment

For the current shell:

```bash
source scripts/setup-env.sh "$FEDRA_ROOT" "$ROOTSYS"
```

With Oracle Instant Client:

```bash
source scripts/setup-env.sh "$FEDRA_ROOT" "$ROOTSYS" /path/to/instantclient_XX_X
```

To make it persistent, add an equivalent `source` command to `~/.bashrc`.

## Optional Oracle / OCCI support

Install Oracle Instant Client **Basic** and **SDK** separately according to Oracle's license and installation instructions.

The resulting directory should contain files similar to:

```text
libocci.so
libclntsh.so
sdk/include/occi.h
```

Then:

```bash
export OCCIHOME=/path/to/instantclient_XX_X
export ORACLE_HOME="$OCCIHOME"
export LD_LIBRARY_PATH="$OCCIHOME:${LD_LIBRARY_PATH:-}"
```

Rebuild FEDRA after setting `OCCIHOME`.

Oracle binaries are deliberately not included in this repository.

## EDA

EDA normally expects a working reconstruction directory containing `lnk.def`.

If your directory contains `lnk_std.def` instead:

```bash
ln -s lnk_std.def lnk.def
```

Then:

```bash
eda
```

### Large linked-track files

Loading every track can consume many gigabytes of RAM. For display-only exploration, EDA supports a cut with `-c`.

Example:

```bash
eda -c 'Entry$%20==0&&nseg>2'
```

This samples approximately one track in twenty after requiring more than two segments.

**Do not use random/subsampled display cuts for physics conclusions or vertex-efficiency calculations.** For analysis, use physically motivated selections or load the complete region/event of interest.

See `examples/eda-lowmem.sh`.

## Repository policy

This project contains only compatibility scripts, documentation, and original helper code.

Do not commit:

- FEDRA's complete original source tree unless its redistribution terms explicitly permit it
- ROOT binary distributions
- Oracle Instant Client files
- OPERA/private collaboration data
- reconstruction ROOT files such as `linked_tracks.root`

See `THIRD_PARTY.md`.


## License

The original helper scripts and documentation in this repository are released under the MIT License.

This license does **not** apply to FEDRA, ROOT, Oracle Instant Client, OPERA data, or any other third-party component.
