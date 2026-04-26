"""Entfernt serviceWorkerSettings aus build/web/flutter_bootstrap.js (BFCache / Lighthouse)."""
import re
import sys
from pathlib import Path


def main() -> int:
    root = Path(sys.argv[1] if len(sys.argv) > 1 else ".").resolve()
    path = root / "build" / "web" / "flutter_bootstrap.js"
    if not path.is_file():
        print(f"skip: {path} nicht gefunden", file=sys.stderr)
        return 0
    s = path.read_text(encoding="utf-8")
    pattern = re.compile(
        r"_flutter\.loader\.load\(\{\s*serviceWorkerSettings:\s*\{[^}]*\}\s*\}\);",
        re.DOTALL,
    )
    new, n = pattern.subn("_flutter.loader.load({});", s, count=1)
    if n:
        path.write_text(new, encoding="utf-8")
        print(f"OK: serviceWorkerSettings aus {path} entfernt")
    else:
        print(f"warn: Pattern nicht gefunden in {path}", file=sys.stderr)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
