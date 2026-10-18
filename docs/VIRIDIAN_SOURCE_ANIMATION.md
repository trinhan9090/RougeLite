# Viridian source animation correction

The active Launch character now uses actual decoded SFF character artwork from the user-specified MVC2_DrDoom-AI(Maro) folder. Procedurally authored body sprites are no longer referenced. Gameplay mechanics, controls and damage rules are unchanged.

| Runtime action | Base AIR action | Evidence |
|---|---:|---|
| Idle | 0 | Source AIR standing loop |
| Move | 20 | Source AIR forward walking loop |
| Basic | 1510 | CNS1510 anim1510+(StateType=A), grounded variant |
| J | 1450 | CNS1450 anim1450 |
| K | 3001 | CNS3001 anim3001+5*(StateType=A), grounded variant |
| L | 1480 | CNS1480 anim1480 |
| I | 3081 | CNS3081 anim3081 |
| Hit | 5000 | Source standing get-hit |
| Death | 5100 | Source knockdown contact, held final pose |

Source tick ratios, offsets and shared feet pivot are preserved. Attack animation total lengths fit existing gameplay action durations. Source horizontal artwork is mirrored for left-facing; north/south names are controller aliases, not newly drawn directions. Up/down movement retains last horizontal facing. No top-down back artwork exists in this source. Atlas clipping prevents neighboring frames bleeding. Generated PNGs are private local runtime assets; source rights remain unverified for distribution.

Launch: close old running game, run root Launch.cmd, CHARACTER fifth slot Viridian, then TRAINING or PLAY. Review idle/movement both sides and Basic/J/K/L/I. Basic retains guaranteed non-voice shot/impact cues. No screenshots/videos exported. Visual acceptance remains with user.

Verified: current-root Launch GUI72checks0failures; Atyu regression54checks0failures; Python7testsOK; Godot import clean. See reports/viridian/20261017/source_actor_live_gui.log, source_actor_atyu_regression.log and source_actor_python.log. Broader VIRIDIAN-01 technical report/performance completion remains separate and unchecked.
