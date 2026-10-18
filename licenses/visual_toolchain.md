# Verified local toolchain / asset provenance

Verified2026-10-16. No purchased asset, downloaded model, proprietary rig or external motion was used. Geometry, outfit, staff, rig, action keys, props, terrain and VFX are original project work generated from versioned scripts. Concepts are user-supplied REFERENCE_ONLY, not sliced/traced into runtime assets; references excluded from the Windows PCK.

| Component | Installed version | Verified license / evidence |
|---|---|---|
| Blender |5.2.2 LTS d13f752e3b9c|GPL2-or-later in the installed copyright.txt, copied as BLENDER_COPYRIGHT.txt; https://www.blender.org/about/license/ confirms artwork/.blend output is not forced under the application GPL.|
| Godot |4.7.2 stable ed1daf0bf|MIT; exact engine and dependency notices in docs/licenses and bundled Windows release.|
| Python image-stage runtime |3.12.14|PSF; runtime is a build dependency, not included in the game.|
| Pillow |12.3.0|Installed metadata and LICENSE specify **MIT-CMU**; copied as Pillow_LICENSE.txt. This supersedes generic older HPND wording in the handoff.|
| NumPy |2.3.5|BSD3-clause copyright/conditions in installed distribution; copied as numpy_LICENSE.txt, including bundled dependency notices.|
| Blender embedded Python/encoder |Bundled with pinned Blender|Native Blender installation and its notices; no pip bpy substitute and no separate paid codec/plugin.|
| Generated runtime assets |v2-astra-benchmark-01|Original-generated; project rights reserved per LICENSE_PROJECT.txt. No invented CC0 grant.|

The first Blender smoke save attempted a thumbnail outside the writable workspace. Generation now sets Blender's save-preview preference to NONE. The prior installation check's online-asset DLL policy error is recorded as an environment issue; local scene generation/rendering is verified and no security policy was changed.

Current native Blender emits API deprecation notices for supported use_nodes properties (future6.0). These are recorded, not presented as a current render failure. No online asset service is required.
