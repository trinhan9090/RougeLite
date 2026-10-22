#!/usr/bin/env python3
"""Generate the original enemy sprite sheets for the time-gated roster.

All art is produced procedurally inside this repository. No third-party sprite
packs, no copyrighted character material, no traced assets.

Usage:
    python tools/generate_enemy_sheets.py

Output:
    assets/art_v3/world/enemy_bulwark.png
    assets/art_v3/world/enemy_skitter.png
    assets/art_v3/world/enemy_marksman.png
    assets/art_v3/world/enemy_ritualist.png
    assets/art_v3/world/enemy_bomber.png
    assets/art_v3/world/enemy_roster_manifest.json

Sheet layout (must match EnemyVisualProfile):
    rows    = action_index * 4 + facing_index
    columns = frame index inside the action block
    facings = south, east, west, north  (west mirrors east)
    actions = idle(2), walk(4), windup(2), attack(2), hit(1), death(3)
"""

from __future__ import annotations

import json
import os
from typing import Dict, List, Sequence, Tuple

from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT_DIR = os.path.join(ROOT, "assets", "art_v3", "world")

TRANSPARENT = (0, 0, 0, 0)

ACTIONS: List[str] = ["idle", "walk", "windup", "attack", "hit", "death"]
FRAMES: Dict[str, int] = {
    "idle": 2,
    "walk": 4,
    "windup": 2,
    "attack": 2,
    "hit": 1,
    "death": 3,
}
FACINGS: List[str] = ["south", "east", "west", "north"]

# Shared dark outline used across every sheet so the roster keeps one family.
OUTLINE = (16, 18, 24, 255)
SHADOW = (16, 21, 34, 128)


class Cell:
    """A tiny RGBA pixel buffer with the few primitives the roster needs."""

    def __init__(self, width: int, height: int) -> None:
        self.w = width
        self.h = height
        self.data: List[List[Tuple[int, int, int, int]]] = [
            [TRANSPARENT] * width for _ in range(height)
        ]

    def put(self, x: int, y: int, color) -> None:
        if color is None:
            return
        x = int(x)
        y = int(y)
        if 0 <= x < self.w and 0 <= y < self.h:
            self.data[y][x] = color

    def rect(self, x: int, y: int, w: int, h: int, color) -> None:
        for yy in range(int(y), int(y + h)):
            for xx in range(int(x), int(x + w)):
                self.put(xx, yy, color)

    def hline(self, x0: int, x1: int, y: int, color) -> None:
        if x1 < x0:
            x0, x1 = x1, x0
        for x in range(int(x0), int(x1) + 1):
            self.put(x, y, color)

    def vline(self, x: int, y0: int, y1: int, color) -> None:
        if y1 < y0:
            y0, y1 = y1, y0
        for y in range(int(y0), int(y1) + 1):
            self.put(x, y, color)

    def line(self, x0: int, y0: int, x1: int, y1: int, color) -> None:
        """Bresenham line, used for splayed limbs."""
        dx = abs(x1 - x0)
        dy = -abs(y1 - y0)
        sx = 1 if x0 < x1 else -1
        sy = 1 if y0 < y1 else -1
        err = dx + dy
        while True:
            self.put(x0, y0, color)
            if x0 == x1 and y0 == y1:
                break
            e2 = 2 * err
            if e2 >= dy:
                err += dy
                x0 += sx
            if e2 <= dx:
                err += dx
                y0 += sy

    def ellipse(self, cx: float, cy: float, rx: float, ry: float, color) -> None:
        if rx <= 0 or ry <= 0:
            return
        for y in range(int(cy - ry), int(cy + ry) + 1):
            for x in range(int(cx - rx), int(cx + rx) + 1):
                dx = (x - cx) / rx
                dy = (y - cy) / ry
                if dx * dx + dy * dy <= 1.0:
                    self.put(x, y, color)

    def shadow(self, cx: float, cy: float, rx: float, ry: float) -> None:
        self.ellipse(cx, cy, rx, ry, SHADOW)

    def outline(self, color=OUTLINE) -> None:
        """Add a one pixel rim around the opaque body only (shadow excluded)."""
        mask = [
            [self.data[y][x][3] == 255 for x in range(self.w)] for y in range(self.h)
        ]
        for y in range(self.h):
            for x in range(self.w):
                if mask[y][x] or self.data[y][x] != TRANSPARENT:
                    continue
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    nx, ny = x + dx, y + dy
                    if 0 <= nx < self.w and 0 <= ny < self.h and mask[ny][nx]:
                        self.put(x, y, color)
                        break

    def fade(self, amount: float) -> None:
        """Blend the body toward transparent (death frames)."""
        if amount <= 0.0:
            return
        for y in range(self.h):
            for x in range(self.w):
                r, g, b, a = self.data[y][x]
                if a == 0:
                    continue
                na = int(a * (1.0 - amount))
                if na <= 0:
                    self.data[y][x] = TRANSPARENT
                else:
                    self.data[y][x] = (r, g, b, na)

    def mirrored(self) -> "Cell":
        out = Cell(self.w, self.h)
        for y in range(self.h):
            for x in range(self.w):
                out.data[y][x] = self.data[y][self.w - 1 - x]
        return out

    def to_image(self) -> Image.Image:
        img = Image.new("RGBA", (self.w, self.h), TRANSPARENT)
        img.putdata([c for row in self.data for c in row])
        return img


def blend(a: Tuple[int, int, int, int], b, t: float):
    """Blend colour a towards b by t (0..1); b may be a colour or None."""
    if b is None:
        return a
    if t <= 0.0:
        return a
    if t >= 1.0:
        return b
    return (
        int(a[0] + (b[0] - a[0]) * t),
        int(a[1] + (b[1] - a[1]) * t),
        int(a[2] + (b[2] - a[2]) * t),
        int(a[3] + (b[3] - a[3]) * t),
    )


def scale(color, factor: float):
    r, g, b, a = color
    return (
        max(0, min(255, int(r * factor))),
        max(0, min(255, int(g * factor))),
        max(0, min(255, int(b * factor))),
        a,
    )


def pose_for(action: str, frame: int) -> Dict:
    """Shared pose table: bob, lean, limb swing and prop offset."""
    if action == "idle":
        return {"dy": 0 if frame == 0 else -1, "lean": 0, "leg": 0, "arm": 0}
    if action == "walk":
        return [
            {"dy": 0, "lean": 0, "leg": 0, "arm": 0},
            {"dy": -1, "lean": 1, "leg": 1, "arm": -1},
            {"dy": 0, "lean": 0, "leg": 0, "arm": 0},
            {"dy": -1, "lean": -1, "leg": -1, "arm": 1},
        ][frame % 4]
    if action == "windup":
        return [
            {"dy": 0, "lean": -2, "leg": 0, "arm": -2, "prop": (-2, -2)},
            {"dy": -1, "lean": -4, "leg": 0, "arm": -3, "prop": (-4, -5)},
        ][frame % 2]
    if action == "attack":
        return [
            {"dy": 1, "lean": 3, "leg": 0, "arm": 2, "prop": (3, 0)},
            {"dy": 0, "lean": 5, "leg": 0, "arm": 3, "prop": (6, 3)},
        ][frame % 2]
    if action == "hit":
        return {"dy": -1, "lean": -3, "leg": 0, "arm": 1}
    return [
        {"dy": 1, "lean": -2, "squash": 0.9, "fade": 0.25},
        {"dy": 3, "lean": -4, "squash": 0.6, "fade": 0.55},
        {"dy": 4, "squash": 0.3, "fade": 0.85},
    ][frame % 3]


def accent_glow(cell: Cell, spec: Dict, view: str, pose: Dict, strength: float = 1.0) -> None:
    """Signature colour pass: cracks, core or tracer glow per archetype."""
    accent = spec.get("accent")
    hot = spec.get("accent_hot", accent)
    if accent is None:
        return
    w, h = cell.w, cell.h
    cx = w // 2
    if spec.get("glow_kind") == "core":
        pulse = pose.get("pulse", 0)
        radius = 2 + int(round(pulse * 2))
        cell.ellipse(cx, h // 2, radius, radius, accent)
        cell.ellipse(cx, h // 2, max(1, radius - 1), max(1, radius - 1), hot)
    elif spec.get("glow_kind") == "cracks":
        dy = pose.get("dy", 0)
        for x, y in spec.get("cracks", []):
            cell.put(x + pose.get("lean", 0), y + dy, accent if strength > 0.5 else hot)
    elif spec.get("glow_kind") == "eyes":
        dy = pose.get("dy", 0)
        for x, y in spec.get("eyes", []):
            cell.put(x + pose.get("lean", 0), y + dy, hot)
    elif spec.get("glow_kind") == "eye":
        dy = pose.get("dy", 0)
        for x, y in spec.get("eyes", []):
            cell.put(x + pose.get("lean", 0), y + dy, hot)


def draw_humanoid(cell: Cell, spec: Dict, view: str, pose: Dict) -> None:
    """Armoured / robed humanoid archetype with an optional prop."""
    w, h = cell.w, cell.h
    cx = w // 2
    dy = pose.get("dy", 0)
    lean = pose.get("lean", 0)
    leg = pose.get("leg", 0)
    arm = pose.get("arm", 0)
    squash = pose.get("squash", 1.0)
    prop_off = pose.get("prop", (0, 0))

    body = spec["body"]
    body_hi = spec["body_hi"]
    body_lo = spec["body_lo"]
    accent = spec.get("accent")
    hot = spec.get("accent_hot", accent)

    ground = h - 8
    torso_top = spec["torso_top"]
    torso_h = int(spec["torso_h"] * squash)
    torso_w = spec["torso_w"]
    head_w = spec["head_w"]
    head_h = spec["head_h"]
    leg_w = spec["leg_w"]
    leg_h = int(spec["leg_h"] * squash)

    if view == "side":
        body_x = cx - torso_w // 2 + lean
    else:
        body_x = cx - torso_w // 2 + lean

    # legs
    if view == "side":
        cell.rect(body_x + 2 + leg, ground - leg_h, leg_w, leg_h, body_lo)
        cell.rect(body_x + 1 + leg, ground - 2, leg_w + 2, 2, body_hi)
    else:
        gap = spec["leg_gap"]
        for side in (-1, 1):
            ox = cx + side * gap - leg_w // 2 + lean
            cell.rect(ox + (leg * side) // 2, ground - leg_h, leg_w, leg_h, body_lo)
            cell.rect(ox - 1 + (leg * side) // 2, ground - 2, leg_w + 2, 2, body_hi)

    # torso
    top = torso_top + dy
    if spec.get("cloak"):
        cell.rect(body_x - 1, top, torso_w + 2, torso_h, body)
        cell.rect(body_x - 2, top + torso_h - 4, torso_w + 4, 5, body_lo)
    else:
        cell.rect(body_x, top, torso_w, torso_h, body)
    # shoulder / chest highlight
    cell.hline(body_x + 1, body_x + torso_w - 2, top + 1, body_hi)
    if spec.get("plate_lines"):
        for row in range(top + 4, top + torso_h - 1, 4):
            cell.hline(body_x + 1, body_x + torso_w - 2, row, body_lo)

    # pauldrons
    if spec.get("pauldrons"):
        pr = spec["pauldron_r"]
        pauldron = spec.get("pauldron_hi", body_hi)
        if view == "side":
            cell.ellipse(body_x + torso_w - 1, top + 2, pr, pr - 1, pauldron)
        else:
            cell.ellipse(body_x - 1, top + 2, pr, pr - 1, pauldron)
            cell.ellipse(body_x + torso_w, top + 2, pr, pr - 1, pauldron)

    # head
    head_x = cx - head_w // 2 + lean
    head_y = top - head_h + 1
    if spec.get("hood"):
        cell.rect(head_x - 1, head_y, head_w + 2, head_h + 1, body_lo)
        cell.rect(head_x, head_y + 1, head_w, head_h - 1, body)
        if view != "north":
            cell.rect(head_x + 1, head_y + head_h - 3, head_w - 2, 2, (12, 10, 14, 255))
        else:
            cell.hline(head_x + 1, head_x + head_w - 2, head_y + 2, body_hi)
    else:
        cell.rect(head_x, head_y, head_w, head_h, body_hi)
        cell.hline(head_x, head_x + head_w - 1, head_y, body_lo)
        if view != "north":
            cell.rect(head_x + 1, head_y + head_h - 3, head_w - 2, 2, (12, 10, 14, 255))
        else:
            cell.hline(head_x + 1, head_x + head_w - 2, head_y + 2, body_lo)

    # prop
    prop = spec.get("prop")
    prop_hi = spec.get("prop_hi", body_hi)
    prop_lo = spec.get("prop_lo", body_lo)
    if prop == "hammer":
        hand_x = cx + spec["leg_gap"] + 4 + lean + arm
        hand_y = top + torso_h - 2 + dy
        px = hand_x + prop_off[0]
        py = hand_y + prop_off[1]
        cell.vline(px, py - 4, py + 4, prop_lo)
        cell.rect(px - 4, py - 10, 9, 6, prop_hi)
        cell.hline(px - 4, px + 4, py - 10, scale(prop_hi, 1.35))
        cell.hline(px - 4, px + 4, py - 5, scale(prop_hi, 0.7))
        cell.put(px - 2, py - 8, accent)
    elif prop == "rifle":
        if view == "side":
            by = top + 5 + dy
            bx = cx - 1 + lean
            cell.rect(bx, by, 20, 3, prop_lo)
            cell.rect(bx + 14, by - 1, 8, 2, prop_hi)
            cell.rect(bx + 2, by + 3, 4, 4, body)
            if pose.get("aiming"):
                cell.rect(bx + 21, by, 4, 1, hot)
        else:
            by = top + 4 + dy
            bx = cx - 3 + lean
            cell.rect(bx, by, 7, 4, prop_lo)
            cell.rect(bx + 6, by - 1, 7, 2, prop_hi)
            if pose.get("aiming"):
                cell.put(cx + 5, by, hot)
    elif prop == "staff":
        hand_x = cx + spec["leg_gap"] + lean + arm
        hand_y = top + torso_h - 2 + dy
        px = hand_x + prop_off[0]
        py = hand_y + prop_off[1]
        cell.vline(px, top - head_h - 4 + dy, ground - 2, prop_lo)
        cell.ellipse(px, top - head_h - 6 + dy, 3, 3, accent)
        cell.ellipse(px, top - head_h - 6 + dy, 2, 2, hot)

    accent_glow(cell, spec, view, pose)


def draw_skitter(cell: Cell, spec: Dict, view: str, pose: Dict) -> None:
    """Low, angular, many-legged sprinter."""
    w, h = cell.w, cell.h
    cx = w // 2
    dy = pose.get("dy", 0)
    lean = pose.get("lean", 0)
    leg = pose.get("leg", 0)

    body = spec["body"]
    body_hi = spec["body_hi"]
    body_lo = spec["body_lo"]
    accent = spec.get("accent")
    hot = spec.get("accent_hot", accent)

    ground = h - 4
    top = 6 + dy

    if view == "side":
        cell.rect(cx - 7 + lean, top + 3, 15, 7, body)
        cell.rect(cx - 6 + lean, top + 2, 12, 2, body_hi)
        cell.rect(cx + 5 + lean, top + 4, 5, 4, body_lo)  # snout
        cell.put(cx + 8 + lean, top + 5, hot)
        cell.rect(cx - 8 + lean, top + 1, 4, 5, body_lo)  # tail
        legs = [(cx - 5, top + 9, -4), (cx + 1, top + 9, 0), (cx + 5, top + 9, 4)]
        for index, (lx, ly, splay) in enumerate(legs):
            swing = (leg if index % 2 == 0 else -leg) * 2
            cell.line(lx + lean, ly, lx + lean + splay + swing, ground, body_lo)
            cell.put(lx + lean + splay + swing, ground, body_hi)
    elif view == "north":
        cell.ellipse(cx, top + 5, 7, 5, body)
        cell.ellipse(cx, top + 4, 5, 3, body_hi)
        for side in (-1, 1):
            for index in range(2):
                lx = cx + side * (3 + index * 3)
                swing = (leg if (index + (0 if side > 0 else 1)) % 2 == 0 else -leg) * 2
                foot = lx + side * 2 + swing // 2
                cell.line(lx, top + 8, foot, ground, body_lo)
                cell.put(foot, ground, body_hi)
    else:
        cell.ellipse(cx, top + 5, 6, 5, body)
        cell.ellipse(cx, top + 4, 4, 3, body_hi)
        cell.rect(cx - 2, top + 5, 4, 2, (10, 12, 16, 255))
        cell.put(cx - 1, top + 5, hot)
        cell.put(cx + 1, top + 5, hot)
        for side in (-1, 1):
            for index in range(2):
                lx = cx + side * (3 + index * 3)
                swing = (leg if (index + (0 if side > 0 else 1)) % 2 == 0 else -leg) * 2
                foot = lx + side * 2 + swing // 2
                cell.line(lx, top + 8, foot, ground, body_lo)
                cell.put(foot, ground, body_hi)

    if accent is not None:
        for x, y in spec.get("eyes", []):
            cell.put(x + lean, y + dy, hot)


def draw_bomber(cell: Cell, spec: Dict, view: str, pose: Dict) -> None:
    """Bulbous husk with an unstable glowing core."""
    w, h = cell.w, cell.h
    cx = w // 2
    dy = pose.get("dy", 0)
    lean = pose.get("lean", 0)

    body = spec["body"]
    body_hi = spec["body_hi"]
    body_lo = spec["body_lo"]

    ground = h - 4
    top = 4 + dy

    if view == "side":
        cell.ellipse(cx + lean, top + 9, 10, 9, body)
        cell.ellipse(cx + lean, top + 7, 8, 6, body_hi)
        cell.ellipse(cx + lean - 4, top + 10, 3, 3, body_lo)
    elif view == "north":
        cell.ellipse(cx, top + 9, 10, 9, body)
        cell.ellipse(cx, top + 7, 8, 6, body_hi)
        cell.ellipse(cx, top + 9, 4, 4, body_lo)
    else:
        cell.ellipse(cx + lean, top + 9, 9, 9, body)
        cell.ellipse(cx + lean, top + 7, 7, 6, body_hi)
        cell.ellipse(cx + lean, top + 9, 4, 4, body_lo)

    # stubby legs
    for side in (-1, 1):
        lx = cx + side * 6 + lean
        cell.vline(lx, top + 15, ground, body_lo)
        cell.put(lx, ground, body_hi)

    accent_glow(cell, spec, view, pose)


def render_cell(spec: Dict, view: str, action: str, frame: int) -> Cell:
    cell = Cell(spec["w"], spec["h"])
    pose = pose_for(action, frame)
    if spec.get("kind") == "skitter":
        draw_skitter(cell, spec, view, pose)
    elif spec.get("kind") == "bomber":
        draw_bomber(cell, spec, view, pose)
    else:
        draw_humanoid(cell, spec, view, pose)
    cell.outline()
    if pose.get("fade"):
        cell.fade(pose["fade"])
    return cell


def build_sheet(spec: Dict) -> Image.Image:
    columns = max(FRAMES.values())
    rows = len(ACTIONS) * len(FACINGS)
    sheet = Image.new(
        "RGBA", (columns * spec["w"], rows * spec["h"]), TRANSPARENT
    )
    for action_index, action in enumerate(ACTIONS):
        for facing_index, facing in enumerate(FACINGS):
            view = {"south": "front", "east": "side", "west": "side", "north": "back"}[
                facing
            ]
            for frame in range(FRAMES[action]):
                cell = render_cell(spec, view, action, frame)
                if facing == "west":
                    cell = cell.mirrored()
                sheet.paste(
                    cell.to_image(),
                    (frame * spec["w"], (action_index * len(FACINGS) + facing_index) * spec["h"]),
                )
    return sheet


ARCHETYPES: List[Dict] = [
    {
        "id": "enemy_bulwark",
        "display": "Iron Bulwark",
        "w": 40,
        "h": 44,
        "kind": "humanoid",
        "body": (62, 66, 80, 255),
        "body_hi": (100, 106, 122, 255),
        "body_lo": (38, 41, 52, 255),
        "accent": (238, 110, 38, 255),
        "accent_hot": (255, 176, 72, 255),
        "glow_kind": "cracks",
        "torso_top": 14,
        "torso_h": 18,
        "torso_w": 22,
        "head_w": 9,
        "head_h": 7,
        "leg_w": 6,
        "leg_h": 6,
        "leg_gap": 6,
        "pauldrons": True,
        "pauldron_r": 5,
        "pauldron_hi": (126, 132, 148, 255),
        "prop_hi": (138, 144, 158, 255),
        "prop_lo": (58, 46, 38, 255),
        "plate_lines": True,
        "prop": "hammer",
        "cracks": [(13, 20), (14, 21), (15, 22), (16, 23), (24, 19), (25, 20), (12, 26)],
    },
    {
        "id": "enemy_skitter",
        "display": "Razor Skitter",
        "w": 24,
        "h": 28,
        "kind": "skitter",
        "body": (44, 62, 72, 255),
        "body_hi": (74, 100, 112, 255),
        "body_lo": (26, 36, 44, 255),
        "accent": (58, 226, 238, 255),
        "accent_hot": (170, 250, 255, 255),
        "glow_kind": "eye",
        "eyes": [(13, 12)],
    },
    {
        "id": "enemy_marksman",
        "display": "Hollow Marksman",
        "w": 32,
        "h": 44,
        "kind": "humanoid",
        "body": (58, 44, 84, 255),
        "body_hi": (92, 72, 128, 255),
        "body_lo": (34, 26, 52, 255),
        "accent": (186, 92, 244, 255),
        "accent_hot": (226, 160, 255, 255),
        "glow_kind": "eyes",
        "torso_top": 16,
        "torso_h": 18,
        "torso_w": 12,
        "head_w": 8,
        "head_h": 7,
        "leg_w": 5,
        "leg_h": 9,
        "leg_gap": 4,
        "hood": True,
        "plate_lines": False,
        "prop": "rifle",
        "prop_hi": (148, 154, 168, 255),
        "prop_lo": (54, 40, 36, 255),
        "eyes": [(13, 12), (14, 12)],
    },
    {
        "id": "enemy_ritualist",
        "display": "Cinder Ritualist",
        "w": 28,
        "h": 48,
        "kind": "humanoid",
        "body": (92, 42, 40, 255),
        "body_hi": (138, 66, 54, 255),
        "body_lo": (52, 24, 26, 255),
        "accent": (255, 142, 40, 255),
        "accent_hot": (255, 214, 128, 255),
        "glow_kind": "eyes",
        "torso_top": 20,
        "torso_h": 20,
        "torso_w": 16,
        "head_w": 8,
        "head_h": 7,
        "leg_w": 5,
        "leg_h": 6,
        "leg_gap": 4,
        "hood": True,
        "cloak": True,
        "plate_lines": False,
        "prop": "staff",
        "prop_lo": (60, 44, 34, 255),
        "eyes": [(12, 18), (13, 18)],
    },
    {
        "id": "enemy_bomber",
        "display": "Volatile Husk",
        "w": 32,
        "h": 36,
        "kind": "bomber",
        "body": (62, 70, 44, 255),
        "body_hi": (96, 106, 62, 255),
        "body_lo": (34, 40, 26, 255),
        "accent": (206, 255, 62, 255),
        "accent_hot": (246, 255, 186, 255),
        "glow_kind": "core",
    },
]


def main() -> None:
    os.makedirs(OUT_DIR, exist_ok=True)
    manifest = {
        "generator": "tools/generate_enemy_sheets.py",
        "origin": "original, generated in-project",
        "licence": "project-owned",
        "layout": {
            "actions": ACTIONS,
            "frames_per_action": FRAMES,
            "facings": FACINGS,
            "row_formula": "action_index * 4 + facing_index",
        },
        "sheets": [],
    }
    for spec in ARCHETYPES:
        sheet = build_sheet(spec)
        path = os.path.join(OUT_DIR, spec["id"] + ".png")
        sheet.save(path)
        manifest["sheets"].append(
            {
                "id": spec["id"],
                "display": spec["display"],
                "file": "assets/art_v3/world/%s.png" % spec["id"],
                "cell": [spec["w"], spec["h"]],
                "size": list(sheet.size),
            }
        )
        print("wrote %s %dx%d" % (path, sheet.size[0], sheet.size[1]))
    manifest_path = os.path.join(OUT_DIR, "enemy_roster_manifest.json")
    with open(manifest_path, "w", encoding="utf-8") as handle:
        json.dump(manifest, handle, indent=2)
    print("wrote %s" % manifest_path)


if __name__ == "__main__":
    main()
