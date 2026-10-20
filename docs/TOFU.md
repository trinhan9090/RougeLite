# Tofu - seventh playable melee Bruiser
Date:2026-10-18. Current source Launch integration; private local prototype. Task TOFU-01. Human visual/listening approval pending.

## Play
Restart Launch.cmd, CHARACTER: seventh avatar Tofu, SELECT, then PLAY or TRAINING. The grid remains20boxes:7available,13unknown. Training dropdown includes Tofu and existing rank/reset controls. WASD, Space, remappableJ/K/L/I and current Auto/Manual unchanged. Manual directional skills use last accepted attack direction, ignoring mouse. Native1920x1080 unchanged. Existing brute class represents the Bruiser role; no class enum/schema change.

## Kit - DEMO DEFAULT data
200HP,215speed,10armor,5%crit x1.5. Basic Cursed-Tool Slash:110px cone,0.55s interval,10/15/30cyclic damage. Actor-owned combo state, no projectile, real shared damage resolver; Echo preserves chosen combo hit.
J Playful Cloud Rush:8sCD,0.08swindup,240px collision-aware rush,6x15hits at0.1s with per-tick/target dedup. Rank2 adds2ticks; rank3stronger final knockback and0.5s nonboss stun; rank4final12%exposed3s. Reuses common bounded Echo and dash-completion hook.
K Debris Projection:14sCD,300px placement,0.35swarning,40slam,110radius.12x7ground ticks at0.5s over6s. Rank2radius132,rank3adds6x8burn ticks over3s,rank4initial nonboss stun1s. Auto chooses reachable dense cluster, Manual uses300px attack-facing endpoint. Echo repeats slam only. Three independent fields maximum per actor in Training, oldest expires without extra damage. Ground ticks do not recursively proc on-hit/on-kill.
L Chain of a Thousand Miles:16sCD,0.1swindup,50/50/50/100 at0.18s; step up to40px between hits, stop35px before locked target. Rank2fifth60hit;rank3finalslow30%2s (boss15%);rank4retarget dead target at most2times. Walls block movement and damage. Echo scales the complete hit sequence once.
I Inverted Spear of Heaven:30sCD,110px acquisition,0.45swindup/invulnerability,150+30combined into one180damage packet to preserve single-nuke proc behavior. Rank2boss+30%=234before defense/crit;rank3CD24s and1s local fear steering on nearby nonbosses (120px,max32,restores AI on expiry/reset). Stun interrupt before commitment refunds50%baseCD. No Echo/Split/Pierce/Multishot/Homing. Knockdown is represented by brief nonboss stun; no new vertical physics system.

The source handoff omits some distances/counts/interval details; above choices are authored DEMO DEFAULT, not newlyLOCKED. Skill unlock3/6/9/11, caps4/4/4/3. All damage/critical/defense/modifier ordering remains shared. Global Cooldown Refund retains current once-per-root on-hit semantics; optional signature evolutions from handoff are not implemented. No new signature/core types introduced.

## Real source art/audio
Local Toji Fushiguro by Soulfire, edits nm-mugen/Rimihf/Dark Night. Source13files unchanged and hashed.2064sprites/317AIR occurrences/320PCM entries extracted,55unselected missing sprite refs flagged.11body clips/44controller aliases and117VFX frames from actual source, stable feet and grid atlases. Source IDs/evidence: reports/tofu/20261018/source_audit.md, mapping_evidence.json, actor_mapping.json and skill_mapping.csv. Source AIR scaling/offsets/flips preserved; timing adapted for game. No actual skeleton data exists in this sprite source.
Body is2_DIR_POC_ONLY: horizontal left/right, vertical input keeps horizontal art; no claim of genuine north/south poses. Only idle source appearance inspected by agent; full action appearance is for owner review. Effect sizing/timing is adapted, not literal fighter collision/cinematic transplant.
Source bank meanings remain CANDIDATE_NOT_LISTENED, includingS200/S500. Runtime deliberately uses deterministic original nonvoice weapon/skill fallbacks; Basic cannot contain spoken clips. T19proves100Basic->100nonvoice cues. Source voices are not integrated until listening confirms them, per handoff. Offline animation_preview.html and sound_catalog.html work locally; no manual import/edit steps needed.

## Verification
Godot4.7.2.stable.official.ed1daf0bf, Windows Compatibility/OpenGL3.3.8Python source tests pass; actual current Launch GUI88checks/0failures, source headless88/0. Twelve affected regression suites pass:Graveshade,Viridian,Doom intro,Atyu,content,damage,original full kits,shared effect matrix,augment combinations,Training,fullscreen aim,maps/bosses. Full48-suite runner was not repeated; new Tofu test is registered. Logs and T01-T20matrix: reports/tofu/20261018/tests.md.
Actual native1920x1080 eight-second dense30mob smoke:8.039385s,413frame samples,median16.579ms,p9551.020ms,max269.886ms; RTX3050Laptop,driver592.82. All4skills accepted; real safe>=550spawn checked before QA-only close placement. Measured average about51.37FPS; median reciprocal about60.32FPS. This short fixture includes initial VFX loading and is not stable60FPS certification. Performance tuning remains open.

## Implementation / limitations
MeleeComboBasic/MeleeSequenceExecutor/MeleeSequenceRuntime are reusable content adapters. Existing CombatService/DamageResolver, context budgets, Echo scheduler, radius modifier and collision primitives are reused. New small source visual adapter binds through metadata; shared VFXfactory/augment core unchanged. Existing six hero gameplay data hashes preserved. Source audio/true4-direction art/public distribution clearance and stable60FPS remain unverified. Original archive and handoff SOURCE_MANIFEST/SOURCE_STATE_INVENTORY were absent; generated audit is not a fabricated archive checksum. Optional source signature variants/cinematic grab/handgun/strikers are excluded.
Current loose source only; old PCK/ZIP not rebuilt. Deployment backup/hashes: reports/tofu/20261018/deployment.json. No QA screenshot/contact-sheet/video exported. Generated PNG/WAV are runtime assets, catalogs are text/HTML. Private third-party art/audio remain excluded from Git/public redistribution; original fallback SFX are locally authored.


### I visual correction — 2026-10-18
Removed source AIR6550 from the ultimate impact because its circular FX embeds a fighter silhouette, producing a duplicate-body artifact. AIR6700 remains source-backed, now preserves its674:618 canvas ratio and plays all52frames once over the existing0.4s event. Combat data/hitbox/damage unchanged. Restart Launch.cmd to load the update. Focused visual timeline:6/6 headless and6/6 GUI; Tofu gameplay:88/88 headless with Launch APPDATA. First unconfigured run had two settings/reset failures and user-log permission errors; configured rerun passes. Human appearance approval pending. Logs: reports/tofu/20261018/ultimate_visual*.log.
Final current-root GUI gameplay regression also passes88/88.


### J visual correction — 2026-10-18
User clarified the reported artifact affects J. Removed AIR1301 helper blade overlay stretched from a thin source image into90x100; source AIR1300 body still retains its actual weapon poses. AIR6151 crescent keeps source proportions (long edge110px), rotates to accepted cast direction and follows32px ahead of caster torso. Existing runtime cancellation removes it at dash end/interruption. No skill damage, hitbox, rank, cooldown or timing changes. Files: scripts/ui/melee_actor_effects.gd, scripts/ui/melee_visual_effect.gd, tests/integration/test_tofu_rush_visual.gd. Godot4.7.2:21/21 focused checks both headless and GUI; I regression6/6. Human visual acceptance pending; restart Launch.cmd and test J in Training. Evidence: reports/tofu/20261018/rush_*.log.

Final current Launch gameplay regression:88checks,0failures (rush_gameplay_gui.log).
