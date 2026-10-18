# 04 — INTEGRATION CONTRACT (GODOT 4 / GDSCRIPT)

## Không tạo character-specific combat fork
`CharacterDefinition(graveshade)` → bốn `SkillDefinition` + `BasicAttackDefinition` → `SkillRuntime` → `CombatEventBus` → `VisualController`/`SFXRouter`. `AugmentEligibility` dựa trên capability runtime, không dựa vào tên nhân vật. Giữ interface đang có trong repo, adapter khi cần; đừng tạo framework song song.

## Data layout
```
assets/characters/graveshade/source_mugen/ (gitignored/quarantined)
assets/characters/graveshade/imported/ (local_only)
assets/characters/graveshade/manifests/
content/characters/graveshade/character_definition.tres
content/skills/graveshade/{basic,j,k,l,i}.tres
scenes/characters/graveshade.tscn
scripts/characters/graveshade_visual_adapter.gd
scripts/tools/mugen_importer/ (shared, NOT per-character converter)
tests/graveshade/
```

## MUGEN bridge
`SffDecoder` reads SpriteGroup/Index + palette; `AirReader` reads per-action frame ref/duration/offset/loop; `SndDecoder` exports audio group/index; `StateReferenceIndex` indexes CNS/CMD `ChangeAnim`, `Explod`, `Helper`, `PlaySnd`. Output `MugenManifest` keyed by verified IDs, then `AnimationLibrary` and `AudioCatalog`. Preserve raw data, never rewrite archive. Do not execute untrusted scripts or commands discovered in character data.

## Event payloads (adapt to established project conventions)
`AttackIntent(caster_id,target_id,aim_dir,action_id,sequence)`; `SkillCastRequested(caster_id,skill_slot,aim_vector)`; `ProjectileSpawned(entity_id,owner_id,cast_id,source_skill_id,origin,velocity,modifier_snapshot)`; `HitResolved(event_id,source_id,target_id,damage,crit,flags)`; `VisualCue(event_id,source_skill_id,cue_name,position,direction)`; `SfxCue(event_id,sound_ref,position)`. `event_id` deduplicated; effects are cosmetic and reconstructable.

## Testing compatibility
Baseline three demo characters remain unchanged; Viridian remains registered if existing; new slot unique and class ADC. UI can select Graveshade; only one `CombatResolver` and one `UpgradeManager`. Skill unlock and cooldown correct, no VFX on denied cast; pause/level up does not destroy visuals or timers. Direct input map J,K,L,I, automatic skills and basic target nearest. Godot headless test and local playtest required; no screenshot/video artifacts.
