# Troubleshooting

## `eda : ERROR: can not open input file: lnk.def`

Run EDA from a FEDRA reconstruction directory.

If the directory contains `lnk_std.def`:

```bash
ln -s lnk_std.def lnk.def
eda
```

## EDA consumes huge amounts of RAM

If startup prints something like:

```text
ReadTracksTree: select 1053937 of 1053937 tracks by cut 1
```

EDA is loading every selected linked track.

For display-only inspection, use a sampling cut:

```bash
eda -c 'Entry$%20==0&&nseg>2'
```

or:

```bash
./examples/eda-lowmem.sh 20
```

Use a physics-motivated complete selection/region for actual analysis.

## `ROOT PCM ... Cint_rdict.pcm file does not exist`

Copy FEDRA-generated PCMs into its library directory:

```bash
find "$FEDRA_ROOT/src" -type f -name '*_rdict.pcm' \
  -exec cp -f {} "$FEDRA_ROOT/lib/" \;
```

The compatibility patch also adds this to the common library build rule.

## `undefined reference to AddRWC` / `AddRWD`

This usually indicates old FEDRA shared-library link rules combined with modern `--as-needed`.

Re-run:

```bash
python3 scripts/patch-fedra.py "$FEDRA_ROOT"
./scripts/build-fedra.sh "$FEDRA_ROOT"
```

Then inspect:

```bash
readelf -d "$FEDRA_ROOT/lib/libDataConversion.so" | grep NEEDED
readelf -d "$FEDRA_ROOT/lib/libEIO.so" | grep NEEDED
```

## `occi.h: No such file or directory`

Oracle applications are optional.

To build them, install Oracle Instant Client Basic + SDK separately and set:

```bash
export OCCIHOME=/path/to/instantclient
export ORACLE_HOME="$OCCIHOME"
export LD_LIBRARY_PATH="$OCCIHOME:${LD_LIBRARY_PATH:-}"
```

Then rebuild.
