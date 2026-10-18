# Graveshade source audit

Source: local Punisher directory; author RAHLONNIR, patch Candido159. Tree SHA256 `c3716cab2317f33cae8a5d7161550cd05746ebf98c437c9b81fa13589e42f4f1`.

Original `marvel P.rar` is not present locally. The previously attached archive was resolved, but its transfer into this execution environment failed; no archive hash or decompression PASS is claimed. Supplied extracted35files are unchanged; five supplied manifest SHA256 hashes match. Archive hash/decompression verification is SKIPPED, not fabricated. Local per-file containment checks reject escaping paths. Source code was parsed as text, never executed.

SFF2.1:700/700 sprites decoded (668 indexedPNG/32LZ5 table entries, linked sprites preserved); failures0. AIR204 declarations, all positive group/index refs resolve; negative-1 frames are intentional empty frames, preserved. SND65 PCM WAV entries decoded and length/hash checked. All DEF references exist, including common1.cns. Parser retains AIR ticks, offsets, flips, loops and collision boxes in source_catalog.json.

## Verified source links

- BASIC: P.cns:1236 StateDef220; effect AIR 619220,620220.
- J: specials.cns:2314 StateDef1011 -> specials.cns:2421 StateDef6191011; effect AIR 6191011,619220.
- K: specials.cns:914 StateDef1006 -> specials.cns:1031 StateDef1007 -> specials.cns:1105 StateDef1008; effect AIR 1007,1008.
- L: specials.cns:2579 StateDef1012 -> specials.cns:2627 StateDef6191012 -> specials.cns:2689 StateDef6201012; effect AIR 6191012,6201012.
- I: hypers.cns:1126 StateDef3005 -> hypers.cns:1222 StateDef3006 -> hypers.cns:1397 StateDef3007 -> hypers.cns:1634 StateDef3008 -> hypers.cns:1690 StateDef3009; effect AIR 3008,3009,6193007.

CMD inputs/MOVELIST agree: standing strong punch z→220; D,F,c SPECIAL9→1011 FN P90; D,B,x SPECIAL4→1006 grenade; D,B,a SPECIAL10→1012 land mine; D,F,a+b HYPER3→3005→3006 launcher and3007 weapon helper→3008rocket→3009explosion. Exact field and controller lines are in mapping_evidence.json. No move was identified solely by StateDef name.

## Runtime adaptation and limitations

Body uses actual source artwork: idle0/walk20/basic220/J1011/K1006/L1012/I3006/hit5000/death5100. Horizontal left/right only; vertical labels are controller aliases, not new rear/front drawings. Fixed pivot and frame clipping preserve alignment. Native relative ticks retained; total active durations adapt to existing game timings. I source separates weapon helper3007 from body3006; runtime source rocket/muzzle effects provide release presentation, without executing cinematic source state machine.

Basic source projectile620220 has empty visual frames. Runtime tracer intentionally reuses intact source FN P90 effect6191011, with muzzle619220; this is an explicit in-package visual adaptation, not a claimed visible source620220 sprite. Source geometry/axes remain cataloged; gameplay effects are normalized to actual hit/range/radius. Source branded character art remains private prototype only; no public redistribution permission established.

Source S0 equipment/effect cue links: basic P.cns:1313 S0,16; J specials.cns:2403 S0,31; grenade throw specials.cns:1018 S0,24 and explosion1165 S0,25; mine deploy2614 S0,24 /detonate2770 S0,25; launcher hypers.cns:1513 S0,38. Auditory timbre was not heard by agent; confidence is CNS/PCM/engine playback, listening/mix approval pending. All S1 spoken-voice entries excluded from Basic. Mono/stereo decoded sounds are local AudioStreamPlayer2D assets; max12voices and gains<=-26dB yield worst-case12correlatedfullscale sum<=0.602, no new audio architecture.

No screenshots, contact sheets, video or recordings produced.

Final muzzle adaptation: original horizontal gun-ready Basic pose starts at source frame1 (frame0 remains cataloged); data-driven SocketProjectileBasic sets actual shared projectile origin32px horizontally mirrored and46px abovefeet. J/K/L/I use peraction sockets32,-38 /8,-30 /0,-12 /34,-42. These are runtime geometry approximations aligned to source weapon/hand poses, not exact imported skeletal sockets. Source has no skeleton. J sustained source animation is not reset by every projectile. Rank3+K source animation also marks the actual3second burning ground; armed source mines pulse and briefly show their true42px trigger ring.

Additive AIR VFX (blendA) use explicit luminance-to-alpha conversion with black cutoff8, followed by transparent bounds cropping. Original decoded sprites/hash catalog unchanged. This prevents opaque black muzzle/explosion rectangles under Godot standard alpha. Manifest records source blend and runtime_blend for each selected frame.
