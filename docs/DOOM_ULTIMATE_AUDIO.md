# Doom ultimate audio - current playable source
Date:2026-10-18. Task:DOOM-AUDIO-01. Branch:feat/doom-ultimate-intro.

## Final requested behavior
- Use the user's replacement file with the same name: assets/private_viridian/audio/hell_answers_to_me_for_i_am_doom (1).mp3,33061bytes,1.986371875seconds. Runtime doom_ultimate_intro.mp3 is a byte-identical private copy. No further trimming, transcription or semantic listening claim.
- Dialogue begins on accepted I. Rays begin after the existing0.65s windup, without waiting for dialogue. Dialogue continues naturally through ray release.
- Caster movement is blocked through windup and the final ray's0.18s window (about1.6seconds total), then restored even if audio is still playing. Positive speed buffs cannot bypass the lock. Actor status/buff timers continue advancing.
- Dedicated AudioStreamPlayer2D is not stolen by ordinary attack SFX. Only one ultimate voice runtime per actor; Training recast replaces the prior tail safely. Pause freezes voice and gameplay. Stun/death/reset/map cleanup cancel the runtime and release only its own lock.
- Existing damage, five/seven/nine rays, two-hit cap, range/fan/ranks,32s normal cooldown, unlocks, Auto/Manual and keybindings unchanged. Basic remains non-voice. Old cast_i SFX removed to prevent overlapping start cues; ray equipment SFX retained.

## Verification
Godot4.7.2.stable.official.ed1daf0bf Windows Compatibility.
Current final replacement audio: source headless21checks/0failures (doom_intro_new_audio_headless.log); actual root GUI23checks/0failures (doom_intro_new_audio_live.log), including real AudioStreamPlayer2D start, rays during voice, natural voice completion, pause, positive speed buff, movement restoration, repeated Training cast, stun/reset/map/dead-caster cleanup. Both final logs contain no warnings/script errors.
Same final parallel runtime before user replaced MP3: full Viridian77checks/0failures; movement12/0; Training85/0. Exact commands: Godot --headless --path worktrees/visual_pipeline_v2 --script res://tests/integration/test_doom_intro.gd; actual GUI --path . --script res://tests/integration/test_doom_intro.gd. Import: --headless --path . --editor --quit. Generator Python compilation passed. Full47-suite runner was not repeated for this focused change; new test registered in tests/run_all.gd.
Initial wait-for-full-voice implementation was superseded by the user's parallel-playback request. A test initially counted fixed physics frames to wait for real audio; corrected to wait for actual completion with a bounded wall-clock deadline. User then supplied the shorter replacement; it is used intact. Old iteration logs are not final acceptance evidence.

## Files
scripts/actors/player_actor.gd; scripts/data/control_mage_executor.gd; scripts/combat/control_mage_runtime.gd; content/characters/viridian_loadout.tres; assets/private_viridian/audio/cues.json; private runtime MP3; tools/mugen_import/viridian_build.py and viridian_content.py; tests/integration/test_doom_intro.gd and test_viridian.gd; tests/run_all.gd; .gitignore; ASSET_LICENSES.md; docs/04_TASKS.md,05_DECISIONS.md,WORK_LOG.md; reports/doom_intro_deployment.json and test logs.
The optional movement guard uses a weak runtime reference; no new public combat/augment interfaces or character-name branches. Audio state belongs to the transient local runtime, not shared Resources.

## Launch / limitations
Restart Launch.cmd to reload current source/audio. PCK/ZIP builds not rebuilt. Backup/hashes in reports/doom_intro_deployment.json. Human listening/visual approval pending. No QA screenshots/videos or audio previews exported. Intermediate PCM decoding used solely to investigate the now-superseded trimming request; no automatic cut was installed. Third-party audio remains private local, redistribution rights unverified.
