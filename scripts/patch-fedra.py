#!/usr/bin/env python3
"""Patch an older OPERA FEDRA tree for modern ROOT/GCC/Linux toolchains.

The patcher is intentionally conservative and idempotent. It only changes
known compatibility patterns. It creates a backup next to every modified file
using the suffix .fedra-modern-linux.bak (once).
"""

from __future__ import annotations

import re
import shutil
import sys
from pathlib import Path

BACKUP_SUFFIX = ".fedra-modern-linux.bak"


def die(msg: str) -> None:
    print(f"[error] {msg}", file=sys.stderr)
    raise SystemExit(1)


def backup(path: Path) -> None:
    b = path.with_name(path.name + BACKUP_SUFFIX)
    if not b.exists():
        shutil.copy2(path, b)


def write_if_changed(path: Path, new: str) -> bool:
    old = path.read_text(errors="surrogateescape")
    if old == new:
        return False
    backup(path)
    path.write_text(new, errors="surrogateescape")
    print(f"[patched] {path}")
    return True


def add_include(path: Path, include: str) -> None:
    if not path.exists():
        return
    s = path.read_text(errors="surrogateescape")
    line = f'#include "{include}"'
    if line in s:
        return

    matches = list(re.finditer(r'^\s*#include[^\n]*$', s, flags=re.M))
    if matches:
        pos = matches[-1].end()
        s = s[:pos] + "\n" + line + s[pos:]
    else:
        s = line + "\n" + s
    write_if_changed(path, s)


def insert_before_targets(makefile: Path, line: str) -> None:
    if not makefile.exists():
        return
    s = makefile.read_text(errors="surrogateescape")
    if line in s:
        return
    m = re.search(r'(?m)^include\s+\.\./config/TargetsDef\.mk\s*$', s)
    if not m:
        print(f"[warn] TargetsDef include not found in {makefile}")
        return
    s = s[:m.start()] + line + "\n" + s[m.start():]
    write_if_changed(makefile, s)


def remove_stale_target(makefile: Path, target: str, srcdir: Path) -> None:
    if not makefile.exists():
        return
    # Only remove the known target if no matching source exists.
    if any(srcdir.glob(target + ext) for ext in (".cpp", ".cxx", ".C", ".cc", ".c")):
        return
    s = makefile.read_text(errors="surrogateescape")
    pat = re.compile(rf'(?m)^.*\$\(BIN_DIR\)/{re.escape(target)}\$\(ExeSuf\).*\n?')
    ns, n = pat.subn("", s)
    if n:
        write_if_changed(makefile, ns)
        print(f"[stale-target] removed {target} ({n} occurrence(s))")


def main() -> None:
    if len(sys.argv) != 2:
        die(f"Usage: {sys.argv[0]} /path/to/FEDRA_ROOT")

    root = Path(sys.argv[1]).expanduser().resolve()
    src = root / "src"
    if not (root / "install.sh").exists() or not src.is_dir():
        die(f"{root} does not look like a FEDRA source root")

    # ROOT headers that older FEDRA relied on indirectly.
    for rel in [
        "libEdb/EdbView.h",
        "libEdb/EdbStage.h",
        "libEdb/EdbVirtual.cxx",
    ]:
        add_include(src / rel, "TMath.h")

    for p in src.rglob("TIndexCell.cpp"):
        add_include(p, "TMath.h")

    # gErrorMutex was removed from modern ROOT.
    p = src / "libEdb/EdbLog.cxx"
    if p.exists():
        s = p.read_text(errors="surrogateescape")
        ns = s.replace("R__LOCKGUARD2(gErrorMutex);", "R__LOCKGUARD(gROOTMutex);")
        if ns != s and '#include "TROOT.h"' not in ns:
            matches = list(re.finditer(r'^\s*#include[^\n]*$', ns, flags=re.M))
            if matches:
                pos = matches[-1].end()
                ns = ns[:pos] + '\n#include "TROOT.h"' + ns[pos:]
            else:
                ns = '#include "TROOT.h"\n' + ns
        write_if_changed(p, ns)

    # ROOT 6.40 no longer accepts the old trailing class/method-string TF1 form.
    for rel, cls in [("libEdb/EdbSigma.cxx", "EdbSigma"), ("libEdb/EdbSEQ.cxx", "EdbSEQ")]:
        p = src / rel
        if not p.exists():
            continue
        s = p.read_text(errors="surrogateescape")
        ns = re.sub(
            rf'new\s+TF1\(([^;]*?),\s*"{re.escape(cls)}"\s*,\s*"[^"]+"\s*\)',
            r'new TF1(\1)',
            s,
            flags=re.S,
        )
        write_if_changed(p, ns)

    # TGLIncludes.h is no longer shipped in current ROOT.
    p = src / "libEDA/EdbEDA.C"
    if p.exists():
        s = p.read_text(errors="surrogateescape")
        ns = s.replace(
            '#include "TGLIncludes.h"',
            "#include <GL/gl.h>\n#include <GL/glu.h>",
        )
        write_if_changed(p, ns)

    # Modern rootcling selection for DataConversion.
    p = src / "libDataConversion/DataConversionLinkDef.h"
    if p.exists():
        s = p.read_text(errors="surrogateescape")
        ns = s.replace("#ifdef __CLING__", "#ifdef __ROOTCLING__")
        if '#pragma link C++ defined_in "libDataConversion.h";' not in ns:
            ns = re.sub(
                r'(?m)^#endif\s*$',
                '#pragma link C++ defined_in "libDataConversion.h";\n\n#endif',
                ns,
                count=1,
            )
        write_if_changed(p, ns)

    # GCC 14 narrowing in comptonmap.
    p = src / "appl/comptonmap/comptonmap.cpp"
    if p.exists():
        s = p.read_text(errors="surrogateescape")
        ns = s
        if "#include <limits>" not in ns:
            matches = list(re.finditer(r'^\s*#include[^\n]*$', ns, flags=re.M))
            if matches:
                pos = matches[-1].end()
                ns = ns[:pos] + "\n#include <limits>" + ns[pos:]
            else:
                ns = "#include <limits>\n" + ns
        ns = re.sub(
            r'float\s+min\s*\[\s*2\s*\]\s*=\s*\{\s*kMaxInt\s*,\s*kMaxInt\s*\}\s*;',
            "float min[2] = { std::numeric_limits<float>::max(), std::numeric_limits<float>::max()};",
            ns,
        )
        ns = re.sub(
            r'float\s+max\s*\[\s*2\s*\]\s*=\s*\{\s*kMinInt\s*,\s*kMinInt\s*\}\s*;',
            "float max[2] = { std::numeric_limits<float>::lowest(), std::numeric_limits<float>::lowest()};",
            ns,
        )
        write_if_changed(p, ns)

    # Modern linker behavior and ROOT PCM placement.
    p = src / "config/TargetsDef.mk"
    if p.exists():
        s = p.read_text(errors="surrogateescape")
        ns = s

        ns = re.sub(
            r'(?m)^\s*\$\(CXX\)\s+-O\s+-shared.*?-o\s+\$\(LIB_TGT\)\s+\$\(OBJ\)\s*$',
            "\t$(CXX) -O -shared -Wl,--no-as-needed -o $(LIB_TGT) $(OBJ) $(LIBS) -Wl,--as-needed",
            ns,
            count=1,
        )

        ns = re.sub(
            r'(?m)^\s*\$\(LD\)\s+\$<.*?-o\s+\$@\s*$',
            "\t$(LD) $< -Wl,--no-as-needed -L$(LIB_DIR) $(LIBS) $(PROJECT_LIBS) -Wl,--as-needed -o $@",
            ns,
            count=1,
        )

        pcm_copy = "\t@if [ -f $(CINT_NAME)_rdict.pcm ]; then cp -f $(CINT_NAME)_rdict.pcm $(LIB_DIR)/; fi"
        if pcm_copy not in ns:
            lib_rule = re.search(
                r'(?m)^(\$\(LIB_TGT\):\s*\$\(OBJ\)\s*\n\t\$\(CXX\)[^\n]*\n)',
                ns,
            )
            if lib_rule:
                block = lib_rule.group(1) + pcm_copy + "\n"
                ns = ns[:lib_rule.start()] + block + ns[lib_rule.end():]
            else:
                print("[warn] Could not locate LIB_TGT rule for PCM copy")

        write_if_changed(p, ns)

    # The old common library recipe did not record these dependencies reliably.
    insert_before_targets(
        src / "libDataConversion/Makefile",
        "LIBS += -L$(LIB_DIR) -lEdb",
    )
    insert_before_targets(
        src / "libEIO/Makefile",
        "LIBS += -L$(LIB_DIR) -lEdb -lEbase -lEdr -lEmath -lDataConversion",
    )
    insert_before_targets(
        src / "libScan/Makefile",
        "LIBS += -L$(LIB_DIR) -lEmath -lEdb -lEbase -lvt -lEdr -lEIO -lEMC -lDataConversion -lAlignment",
    )

    # Known stale targets in archived trees. Remove only when source is absent.
    remove_stale_target(src / "appl/emrec/Makefile", "emrawcorr", src / "appl/emrec")
    remove_stale_target(src / "appl/emrec/Makefile", "emrawbeammap", src / "appl/emrec")
    remove_stale_target(src / "appl/viewcorr/Makefile", "cp2mos", src / "appl/viewcorr")

    print("[done] FEDRA compatibility patch pass completed.")
    print("[next] Run scripts/build-fedra.sh /path/to/FEDRA_ROOT")


if __name__ == "__main__":
    main()
