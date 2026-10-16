class_name CastBudget
extends RefCounted
## Shared by every descendant. Counters never reset when an event branches.
const MAX_DEPTH: int = 3
const MAX_PROCS: int = 32
const MAX_PROJECTILES: int = 64
var procs: int = 0
var projectiles: int = 0
var deepest: int = 0
var events: int = 0
var seen: Dictionary[String, bool] = {}
var depth_limit: int = MAX_DEPTH
var proc_limit: int = MAX_PROCS
var projectile_limit: int = MAX_PROJECTILES

func configure(limits: CombatLimitsDefinition) -> void:
	depth_limit = limits.chain_depth
	proc_limit = limits.secondary_procs
	projectile_limit = limits.projectiles_per_root

func claim(key: String) -> bool:
	if seen.has(key): return false
	seen[key] = true
	return true

func spend_proc(depth: int) -> bool:
	if depth > depth_limit or procs >= proc_limit: return false
	procs += 1
	deepest = maxi(deepest, depth)
	return true

func spend_projectile() -> bool:
	if projectiles >= projectile_limit: return false
	projectiles += 1
	return true
