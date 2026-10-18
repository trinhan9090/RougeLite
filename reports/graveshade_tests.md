# Graveshade test results

Status: PLAYABLE_TECH_TESTED. OverallGRAVESHADE-01 remains unchecked for archive verification/human visual acceptance and performance target follow-up. No screenshot/video evidence requested or exported.

Environment: Windows, Godot4.7.2.stable.official.ed1daf0bf, Compatibility/OpenGL3.3, AMD Ryzen5 6600H, NVIDIA RTX3050Laptop. Current Launch runs root source.

Final focused currentLaunch GUI:77checks0failures (`reports/graveshade/live_gui_final.log`). Shared decoder regression:8testsOK. Source/asset verification:10tests,9pass/1archiveSKIP (`python_final.log`). Final regression_final.log contains46suites0failures; final expansion/death cases exercised separately in currentLaunch77checks.

| ID | Result | Evidence / scope |
|---|---|---|
|T01|PARTIAL|35 source files safely contained/hash verified. Attached originalRAR resolved but materialization failed; no archive hash/decompression proof. Python1skip.|
|T02|PASS|All DEF resource references exist; supplied five source SHA256 values match.|
|T03|PASS|700/700 decoded,204AIRactions,100% positive sprite references resolve; intentional negative blank frames retained.|
|T04|PASS / LISTENING_PENDING|65PCM entries decoded; real source cues load/play via AudioStreamPlayer2D; no subjective timbre claim.|
|T05|PASS|Source S0 equipment cues on accepted runtime events; basic excludes S1 voice bank; no cast events on denied cooldown.|
|T06|PASS|Shared source pivot/offsets, clipped nearest atlases, horizontal mirror; final live check verifies source-art muzzle socket.|
|T07|PASS|Only horizontal source artwork; north/south names are controller aliases, not fake rear animation.|
|T08|PASS|Actual projectile basic15 selects nearest only.|
|T09|PASS|No basic beyond340acquisition range.|
|T10|PASS|J5/7roundevents,22degreefan,actual shared projectiles and max5targethits/activation; rank4mark after3hits.|
|T11|PASS|K.7sfuse before80AOE; each activation explosion hits a target once.|
|T12|PASS|K endpoint clamps before obstacle and radial visibility blocks through-wall damage; boss is not knocked back.|
|T13|PASS|L2/3mines, max6owner, oldest removed silently.|
|T14|PASS|12slifetime expiry removes mine without detonation; reset/death cleanup checked.|
|T15|PASS|Rank4firstmine chains armed neighbors within120, detonatedflag prevents recursion/duplicate release.|
|T16|PASS|I.45swindup,1/3real projectiles,460speed/650range/28CD; rank3threeclusterstrikes.|
|T17|PASS|Shared root claims allow max2rocketexplosions/target and maxone hit per each of3cluster pulses; auxiliary damage45% and cluster40%.|
|T18|PASS|Auto/Manual common executors; actual sixth avatar→PLAY; current remappable physical J binding accepted.|
|T19|PASS|Free unlocks3/6/9/11 retained.|
|T20|PASS|Rankcaps4/4/4/3 validated.|
|T21|PASS|Real shared Split binds Basic/J; rejectedK/L/I. Echo all4active; AreaK/L/I; generic eligibility unchanged.|
|T22|PASS|Two mutually excluding fixture cores reject opposite order on real J runtime; optional signatures not added.|
|T23|PASS|Root projectile/proc/depth limits retained; Split shared factory, J Echo replays once with separate activation hit counter; no echo-of-echo.|
|T24|PASS|Pause freezes events; real level-up gives3validchoices and selected offer resumes PLAY; ordnance cleanup on death.|
|T25|PASS|Full46suite regression including five prior heroes; old hero gameplay source files SHA comparison unchanged. New optional presentation metadata defaults preserve old behavior.|
|T26|PASS|Source/currentLaunch import, boot and focused scene checks executed inGodot4.7.2.|
|T27|PASS|Real wall600.012s;30/60/120mobs;137927gameplayevents; finalphaseRUNNING; failures0. Initial336.614sincomplete run preserved as failed.|
|T28|PASS / MIX_PENDING|12AudioStreamPlayer2D voices/64pending max; gain<=-26dB, component worst-case correlated12voice peak<=.602. Subjective listening/bus mix approval pending.|
|T29|TECH_PASS / VISUAL_PENDING|Actual source actor/effects played inGUI77checks and real mob stress; user directly reviews readability/art. No QA media.|
|T30|PASS|Scoped newhero/data/presentation/tooling/tests/docs; priorfivehero gameplay files unchanged; Doom presentation-only reduction is explicitly requested.|

## Executed commands

```powershell
python -X utf8 tools/mugen_import/audit_directory.py --source D:/SelfProject/RougeLite/assets/characters/newADC/Punisher --out reports/graveshade --data experiments/graveshade/data
python -X utf8 tools/mugen_import/graveshade_content.py
python -X utf8 tools/mugen_import/graveshade_build.py
python -X utf8 tools/mugen_import/test_graveshade.py
python -X utf8 tools/mugen_import/test_decoder.py
Godot_v4.7.2-stable_win64_console.exe --headless --path . --import
Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tests/run_all.gd
Launch.cmd --script res://tests/integration/test_graveshade.gd
Launch.cmd --windowed --resolution 960x540 --script res://tests/integration/soak_graveshade.gd
Launch.cmd --windowed --resolution 960x540 --script res://tests/integration/soak_graveshade.gd -- --quick-probe
Launch.cmd --script res://tests/integration/test_viridian.gd
```

## Stress measurements

| Mobs | Samples | Median ms | p95 ms | p99 ms |
|---|---:|---:|---:|---:|
|30|8423|16.682|65.656|133.351|
|60|6477|17.392|118.257|201.506|
|120|2339|38.080|338.578|502.480|

600s run: max1158nodes, max6mines, max12active voices, final static memory60453408bytes. This is final static memory, not measured peakRAM. CPUhardware and frame times recorded, not CPU% profiling.

QA-only detached fixture cap120 (normal cap110 unchanged), immortal actors, realAI/navigation/projectile/damage, forced4second casts. Window960x540, with regression processes also running. Measurements are not isolated benchmarks, do not prove60FPS at native1920x1080, and do not establish Graveshade-only overhead. Stress clearly shows frame spikes at high population; no balancing/spawn safety settings were reduced to hide them.

After final muzzle/source-alpha adaptation: currentLaunch focused77checks passed and quick live30/60/120probe completed12.01s with0failures.600ssoak covers preceding same ordnance/lifecycle implementation; final asset/presentation/muzzle adjustments were verified by these focused/quick runs.

## Historical failures retained

Initial test fixture used wrong augment filenames and invalid mine trigger position; corrected fixture, not damage numbers. Training reset test now actually resumes PAUSEDscene before requesting reset. J Echo originally shared the primary activation hit limiter; fixed by isolating counters by is_echo while preserving shared root budgets. Source additive VFX initially retained opaque black pixels; converted additive blend to explicit luminance alpha and added real-pixel verification. Source generator duplicate metadata keyword was fixed; final Pythoncompile/build passed. Initial soak exited336.614s when scene left RUNNING; exact phase was not recorded then. Input-isolated repeat passed600.012s. Original logs are preserved and are not presented as passes.

Doom/Viridian latest currentLaunch GUI:73checks0failures, including explicit22x11bolt/16impact profile assertion and unchanged full kit/boss/map transitions. See graveshade/doom_visual_regression.log.
