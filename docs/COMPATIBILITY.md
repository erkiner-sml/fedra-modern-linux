# Compatibility notes

## Confirmed configuration

The initial compatibility work was validated on:

- Debian GNU/Linux 13 (Trixie)
- GCC 14.2
- ROOT 6.40.04
- x86_64 Linux

A successful `makeall.sh check` included:

- reconstruction utilities
- `eda`
- `emlink`
- `emalign`
- `emaligns2s`
- `emalignraw`
- `makescanset`
- `emtra`
- `emshow`
- `emrec`
- `emvtx`
- `emcheck`
- `empred`
- `emtrackan`
- `rwcToEdb`
- `viewdist`
- `mc2raw`
- Oracle applications when OCCI was configured

## Why modern systems expose these problems

Older FEDRA build files assumed behavior from older ROOT releases and older ELF linker defaults.

Modern systems may expose:

1. ROOT headers that are no longer included transitively.
2. Removed ROOT internals such as `gErrorMutex`.
3. ROOT API changes in callable `TF1` constructors.
4. Removal of `TGLIncludes.h`.
5. Stricter dictionary/module handling and PCM lookup.
6. Newer GCC diagnostics such as narrowing conversion errors.
7. `--as-needed`, which can discard libraries that old link recipes expected to remain.
8. Old application targets whose sources are absent from a particular archive.

The patch script targets these specific compatibility issues instead of modifying physics/reconstruction algorithms.
