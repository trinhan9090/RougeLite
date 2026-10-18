# Fullscreen and last-attack Manual direction
Date:2026-10-17
Status:Approved by latest explicit user request

User requests full-window game GUI and a Manual direction indicator under the feet that follows the character's most recent attack instead of player movement. Supersedes movement-directed Manual input only. Keep nearest-target automatic basic, all skills/ranks, Auto behavior and Astra L nearest-target assistance.

PlayerActor owns a separate normalized attack_direction, RIGHT before the first accepted attack. Accepted basics record melee target direction or actual ranged interception direction. Accepted directed active casts record their direction; rejected casts and self buffs do not rotate it. WASD updates visual facing only. Manual directional commands use attack_direction; Astra L still assists nearest enemy and uses attack direction only for empty Manual fallback (Auto fallback unchanged).

A child ground-plane indicator draws a flattened ellipse/arrow below feet, behind actor art. Latest user clarification requires an actual1920x1080 render viewport and1920x1080 default window, not upscaling the former640x360 viewport. Fullscreen starts at native1080p on this display; fractional/expand is only a fallback for other window sizes. Menu/HUD now use native1:1 UI coordinates and adapt to the real viewport. Original sprite textures remain native pixel art. Settings schema and other gameplay ownership/interfaces remain unchanged; new actor helper/state are an approved input implementation extension.

Tests: accepted basic and skill direction, movement independence, invalid input/rejected cast stability, ranged direction, responsive bounds at irregular resolutions, four hero regressions, headless and real renderer. No QA media exports.

Native rendering uses a2x world camera to retain the existing approximate character size in screen pixels; HUD remains1:1, not a640x360 frame enlargement. Spawn exclusion uses viewport/camera.zoom in world coordinates, keeping offscreen20px margin and550px minimum player distance unchanged. This is display geometry, not relaxed spawn validation.
