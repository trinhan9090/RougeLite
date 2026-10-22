# Graveshade — Tactical Suppressor

Current root Launch.cmd includes Graveshade as fifth hero. Restart game, CHARACTER→fifth avatar→SELECT, then PLAY or TRAINING. Twenty avatar slots remain;14areunknown. Use existing WASD/Space/J/K/L/I and saved key bindings. Auto/Manual uses existing controller; Manual retains last accepted attack direction. Training has immortal stationaryboss, fullHP, zeroactiveCD and rank selector.

Actual source animation comes from assets/characters/newADC/Punisher, not a generated character substitute. Side-facing left/right only; no fabricated north/south drawings. Sources remain unchanged. All collision/damage/augments use shared services.

| Move | Rank behavior / default |
|---|---|
| Basic Tactical Round |115HP,210speed;15physical,.36interval,340range,680bullet speed,5%crit/1.5x. Noammo. Nearest valid target; Space uses same attack. |
| J Suppression Burst |CD6.2;5x12→7rounds,22degreefan; max5hits/target/activation. Rank3first round pierces1. Rank4after3hits EXPOSED+12%playerdamage3s. |
| K Frag Deployment |CD11; .7fuse,80damage,105radius→126rank2. Rank3burningground3seconds,16/sec. Rank4two50%secondaryblasts, no recursive explosion chain. Auto chooses cluster; Manual uses current attack direction. Walls checked; bosses not pushed. |
| L Tactical Minefield |CD16;2→3mines,arm.5s,life12s,trigger42,radius78,65damage; max6owner evicts oldest silently. Rank3slow30%2s. Rank4firstmine chains armed neighbors within120 once. Boss damage45.5before defense. |
| I Heavy Ordnance |CD28,windup.45;460speed,650distance,260damage,radius145. Rank2three rockets, side45%,±12degrees,max2rocketexplosions/target/root. Rank3main impact adds3x40%clusterstrikes,.25s apart; each pulse hits at mostonce. Auto favors boss then density. |

Unlocks3/6/9/11; ranks4/4/4/3. DEMO DEFAULT values remain tunable, not newLOCKED decisions. Source slots use actual220/1011/1006/1012/3006body actions; exact source graph and effect/sound links in reports/graveshade_source_audit.md and reports/graveshade/mapping_evidence.json.

Augments: shared Split/Pierce/Multishot/Homing on Basic/J; Echo on allfouractives with existing safety limits; Area Expand onK/L/I. Split rejected on grenades/mines/rockets. Optional signatures/new core types were not added. No changes to existingfivehero gameplay content.

Doom/Viridian Basic VFX also reduced from28x14to22x11 and impact20to16, with damage/radius unchanged.

Direct review: test Basic and eachslot at rank1/4(I3), compare Auto/Manual, nearby wall and boss, repeatedmine casts/cap, Iimpact/expiry, pause/upgrade and cleanup. Artwork and sound approval remain yours. No screenshot/video/contact sheet output. See reports/graveshade_tests.md and graveshade_blockers.md for exact evidence/limitations.
