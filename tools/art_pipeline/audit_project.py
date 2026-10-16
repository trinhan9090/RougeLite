"""A0 immutable asset inventory and recoverable source snapshot."""
import csv
import hashlib
import json
import platform
from pathlib import Path
import zipfile
from PIL import Image, __version__ as pillow_version

ROOT = Path(__file__).resolve().parents[2]


def main():
    output = ROOT / "docs/art_baseline"
    output.mkdir(parents=True, exist_ok=True)
    if (output / "pre_art_source.zip").exists():
        raise SystemExit("Refusing to overwrite the A0 baseline snapshot/inventory")
    files = sorted(p for folder in ("assets", "scripts", "scenes", "content")
                   for p in (ROOT / folder).rglob("*") if p.is_file()
                   and p.suffix != ".import")
    files += [ROOT / "project.godot"]
    rows = []
    for path in files:
        row = dict(path=path.relative_to(ROOT).as_posix(), bytes=path.stat().st_size,
                   sha256=hashlib.sha256(path.read_bytes()).hexdigest(),
                   dimensions="", mode="")
        if path.suffix.lower() == ".png":
            with Image.open(path) as image:
                row.update(dimensions=f"{image.width}x{image.height}",mode=image.mode)
        rows.append(row)
    with (output / "inventory.csv").open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=rows[0].keys())
        writer.writeheader()
        writer.writerows(rows)
    archive = output / "pre_art_source.zip"
    if archive.exists():
        raise SystemExit("Refusing to overwrite the A0 baseline snapshot")
    with zipfile.ZipFile(archive,"w",zipfile.ZIP_DEFLATED) as target:
        for path in files:
            target.write(path,path.relative_to(ROOT))
    (output / "environment.json").write_text(json.dumps(dict(
        python=platform.python_version(),pillow=pillow_version,
        git="main; no commits; existing files untracked",
        godot="4.7.2.stable.official.ed1daf0bf",files=len(rows)),indent=2))
    print(f"A0_SNAPSHOT files={len(rows)} archive={archive.relative_to(ROOT)}")


if __name__ == "__main__": main()
