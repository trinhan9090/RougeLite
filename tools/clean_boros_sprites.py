"""Rebuild derived strips, retaining the main 8-connected alpha component per cell.

The prototype contains disconnected fragments from neighbouring poses inside
its frame cells. Originals are untouched; gameplay never runs this conversion.
"""
from collections import deque
import json
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "assets/sprites/characters/boros/boros_sprite_pack/sprites"
OUTPUT = ROOT / "assets/sprites/characters/boros/cleaned"


def components(image):
    width, height = image.size
    alpha = image.getchannel("A").tobytes()
    seen = bytearray(width * height)
    result = []
    for seed, opacity in enumerate(alpha):
        if not opacity or seen[seed]:
            continue
        queue = deque([seed])
        seen[seed] = 1
        points = []
        while queue:
            point = queue.popleft()
            points.append(point)
            x, y = point % width, point // width
            for ny in range(max(0, y - 1), min(height, y + 2)):
                for nx in range(max(0, x - 1), min(width, x + 2)):
                    neighbour = ny * width + nx
                    if alpha[neighbour] and not seen[neighbour]:
                        seen[neighbour] = 1
                        queue.append(neighbour)
        result.append(points)
    return sorted(result, key=len, reverse=True)


def clean_frame(image):
    groups = components(image)
    if len(groups) <= 1:
        return image.copy(), 0, 0
    mask = bytearray(image.width * image.height)
    for point in groups[0]:
        mask[point] = 255
    result = image.copy()
    alpha = image.getchannel("A")
    retained = Image.frombytes("L", image.size, bytes(mask))
    # Preserve original soft-edge alpha on retained pixels.
    from PIL import ImageChops
    result.putalpha(ImageChops.multiply(alpha, retained))
    return result, len(groups) - 1, sum(map(len, groups[1:]))


def main():
    OUTPUT.mkdir(parents=True, exist_ok=True)
    report = []
    for source in sorted(SOURCE.glob("*.png")):
        image = Image.open(source).convert("RGBA")
        if image.height != 128 or image.width % 128:
            raise ValueError(f"Invalid source dimensions: {source.name}")
        output = Image.new("RGBA", image.size)
        for index in range(image.width // 128):
            frame = image.crop((index * 128, 0, (index + 1) * 128, 128))
            cleaned, count, pixels = clean_frame(frame)
            output.paste(cleaned, (index * 128, 0))
            if count:
                report.append(dict(file=source.name, frame=index,
                                   removed_components=count, removed_pixels=pixels))
        output.save(OUTPUT / source.name)
    evidence = ROOT / "docs/evidence/boros-fragment-cleanup.json"
    evidence.write_text(json.dumps(report, indent=2), encoding="utf-8")
    print(f"CLEANED strips={len(list(OUTPUT.glob('*.png')))} "
          f"affected_frames={len(report)} removed_pixels="
          f"{sum(row['removed_pixels'] for row in report)}")


if __name__ == "__main__":
    main()
