# Atyu — source audio, private local test

2026-10-17. Task ATYU-AUDIO-01. No combat numbers, rank tables, skill ownership or input rules changed. No QA images/videos exported.

## Basic sound correction — 2026-10-17

Latest user request: remove voices from all basic combo variants. Basic/combo_2 now play only sword S0,4 at2/60s; combo_1 only sword S0,2 at start. Impact S1,23 and J/K/L/I cues remain unchanged. Historical source voice references below explain provenance, not current basic playback. The unused original5,36 WAV is retained locally.

## Extraction and provenance

`tools/mugen_import/build_audio.py` reads the supplied `Ichigo_Bankai.snd` and all six CNS files without executing MUGEN code. It extracts **134 WAV occurrences losslessly**, validates PCM lengths and records SHA256, rate, channels, duration and CNS triggers in `docs/atyu_audit/audio_inventory.json`. Full extraction: `experiments/mugen_atyu/audio/` (excluded from Godot import). Only **11 selected WAVs** are copied into `assets/private_atyu/audio/` for gameplay.

The supplied SND has duplicate key500,10; both occurrences are preserved (`500_10_duplicate_112.wav`). Neither is used in gameplay. Its final next pointer equals EOF rather than zero; both valid termination forms are accepted. Cycles, truncation, invalid signatures and non-WAV payloads fail extraction. The first attempt rejected these source peculiarities; parser was corrected and tests rerun.

## Mapping

| Game action | Source evidence | Playback in game |
|---|---|---|
| Basic 1 | Ichigo_Bankai CNS200: S5,36 time0; S0,4 time2; HitDef S1,23 | Sword only at2/60s; actual accepted impact |
| Basic 2 | CNS210: S5,35 and S0,2 time0 | Sword S0,2 only at resolved combo_1 animation start |
| Basic 3 | CNS211: S5,35 time0 and S0,4 time2 | Sword S0,4 only at2/60s |
| J | CNS210 / AIR210 | S5,35 at animation start; S0,2 at actual cone/slash resolution (.15s) |
| K | Vizard CNS910 / AIR900: repeated S5,38 time0; S166,0 time10 is absent | One S5,38 at start. S500,12 from source Rika state900 substitutes the missing control sound when the seal actually appears (.2s); no seal sound on invalid/immune target |
| L | Vizard188100 AIR2001: S500,11 animelem2; Ichigo930 AIR10190 S500,16; Ichigo940 AIR10230 S500,13 animelem2 | Call at2/60s; companion appearance; each real companion strike/attack VFX |
| I | Especiales1434/1435 AIR1406/1401;1435 repeats S0,4; helpers1430/1450 reference absent S5,19/S5,18 | One S0,4 at charge start. Existing S5,21 energy sound from Vizard CNS substitutes absent helper beam sound at real beam/VFX resolution (.4s) |
| Impact | Basic HitDef S1,23 | Actual positive accepted player damage; shared impact sample also used for active hits |

This is an adaptation to the existing survival-game kit, not a full CNS interpreter. Source cinematic delays, super-pause, repeated identical PlaySnd blocks and extreme volume999 are intentionally not reproduced. Basic2/3 source-specific HitDef sounds1,22/1,20 are inventoried but the current game uses one impact sample1,23. Missing source sounds remain explicitly listed in inventory (`exists:false`). No synthesized replacement is claimed to be original audio.

## Runtime

`SpriteFrames` metadata selects the JSON cue profile. `ActionAudio` belongs to each player actor; it preloads streams and reuses twelve `AudioStreamPlayer2D` voices with a64-event pending limit. It follows the actor's world position. Delayed cues use physics time, pause with the tree, stop on death/reset/map transition and are destroyed with their actor. At capacity the first voice is reused. Gain is conservatively configured per cue (-14 to-20dB), independently of MUGEN's excessive volume settings. Player action audio replaces the old synthetic hit tone for its own outgoing hits; other actors/heroes retain prior feedback.

ActorSprite emits the resolved action after choosing the combo variant. Cone, seal, companion strikes and beam dispatch at their real runtime/VFX branch; no separate audio countdown guesses when damage occurs. Ordinary PLAY and TRAINING share the same adapter. Headless tests count dispatched cues but never claim audible playback; GUI tests inspect actual running audio players. Human listening/mix approval remains pending.

## Reproduce and test

From project root with local Python and Godot paths documented in WORK_LOG:

1. `python tools/mugen_import/build_audio.py`
2. `python tools/mugen_import/test_audio.py`
3. `godot --headless --path . --import`
4. `godot --headless --path . --script res://tests/run_all.gd`
5. `Launch.cmd --script res://tests/integration/test_atyu_audio.gd` for GUI playback checks.

For listening: reopen `Launch.cmd`, CHARACTER → Atyu → SELECT → TRAINING; choose MANUAL, disable automatic basic, use Space/J/K/L/I. Keep the stationary boss in range. Compare voice/swing, seal, companion and beam to their displayed actions, then test pause/reset. Normal PLAY unlock levels remain3/6/9/11.

## Rights and limitations

These are sounds from the user-supplied third-party MUGEN mod credited to Mugen Matias, not newly authored or verified permissive assets. The latest user explicitly authorizes extracting/reusing them for this local Atyu test. WAVs and full raw extraction remain ignored by Git; do not publicly distribute this private build/audio without rights clearance. No new paid tools or runtime network dependencies. Actual perceived loudness, timbre and listening quality require the user's direct test; device output is not captured or asserted.

## Executed verification

Godot4.7.2.stable.official.ed1daf0bf / Windows / Compatibility renderer (GUI reports RTX3050 Laptop). Python3.12.14 standard library only. Two Python tests PASS;44 canonical suites PASS; final source focused54 checks PASS; actual root Launch54 headless and56 GUI checks PASS. GUI confirms running AudioStreamPlayer2D streams, not captured device output. See audio_* logs in docs/atyu_audit and WORK_LOG. Earlier failed import/fixture/timer logs are retained and superseded by final logs.

ATYU-AUDIO-02 verification:53 focused headless and55 current Launch GUI checks pass after removing basic voices. Three sword-only cue mappings and all unchanged active/impact profiles checked. See audio_basic_sfx_* logs.
