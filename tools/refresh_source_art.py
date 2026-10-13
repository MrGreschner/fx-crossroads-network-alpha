"""Run from any directory after editing SVG artwork; no extra dependencies."""
from pathlib import Path
import json
project = Path(__file__).resolve().parents[1]
sources = {
    "res://" + path.relative_to(project).as_posix(): path.read_text(encoding="utf-8")
    for path in sorted((project / "assets").rglob("*.svg"))
}
(project / "content" / "source-art.json").write_text(
    json.dumps(sources, separators=(",", ":")), encoding="utf-8"
)
print(f"Embedded {len(sources)} editable SVG sources.")
