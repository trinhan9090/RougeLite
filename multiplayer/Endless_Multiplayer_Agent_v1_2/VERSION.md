# Multiplayer Handoff v1.2

Supersedes v1.1 **map transitions and ticket batching**. The multiplayer demo randomly chooses/generates **one map at run start, never changes it during the run**. Bosses appear every 180 elapsed seconds, even concurrently, and defeating one never changes map. Shared score uses team survival time. Individual progression and unpaused/unprotected Augment selection remain. F revive locks offensive casting while held. New match => new run ID and newly sampled map seed.
