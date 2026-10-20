class_name ExpOrbAuthority
extends Node
## Host-authoritative EXP orb spawning, claiming, and credit.
## First eligible player within pickup radius claims atomically; no double-claims.

signal orb_spawned(orb_id: int, position: Vector2, exp_amount: int)
signal orb_claimed(orb_id: int, player_id: int, exp_amount: int)

var _orbs: Dictionary = {}  # orb_id → OrbState
var _next_orb_id: int = 1

const DEFAULT_PICKUP_RADIUS: float = 80.0
const MAGNET_RADIUS: float = 120.0

class OrbState:
	var orb_id: int
	var position: Vector2
	var exp_amount: int
	var spawned_tick: int
	var claimed: bool = false
	var claimer_player_id: int = -1
	var node: Node = null

func spawn_orb(position: Vector2, exp_amount: int) -> int:
	if not multiplayer.is_server():
		push_error("ExpOrbAuthority: Only server can spawn orbs")
		return -1

	var orb_id := _next_orb_id
	_next_orb_id += 1

	var orb := OrbState.new()
	orb.orb_id = orb_id
	orb.position = position
	orb.exp_amount = exp_amount
	orb.spawned_tick = Time.get_ticks_msec()

	_orbs[orb_id] = orb
	orb_spawned.emit(orb_id, position, exp_amount)

	# Broadcast to clients
	rpc("_client_receive_orb_spawn", orb_id, position, exp_amount)

	return orb_id

@rpc("authority", "reliable")
func _client_receive_orb_spawn(orb_id: int, position: Vector2, exp_amount: int) -> void:
	# Client creates visual orb node
	# TODO: Integrate with existing orb spawner
	pass

func try_claim_orb(player_id: int, orb_id: int, player_position: Vector2) -> bool:
	if not multiplayer.is_server():
		return false

	var orb := _orbs.get(orb_id) as OrbState
	if orb == null:
		return false

	if orb.claimed:
		return false

	# Check distance (server authoritative positions)
	var distance := player_position.distance_to(orb.position)
	if distance > DEFAULT_PICKUP_RADIUS:
		return false

	# Atomic claim
	orb.claimed = true
	orb.claimer_player_id = player_id

	# Grant EXP (will be handled by progression system)
	orb_claimed.emit(orb_id, player_id, orb.exp_amount)

	# Broadcast claim to all clients
	rpc("_client_receive_orb_claimed", orb_id, player_id)

	# Clean up after short delay (for visual feedback)
	_schedule_orb_removal(orb_id, 0.1)

	return true

@rpc("authority", "reliable")
func _client_receive_orb_claimed(orb_id: int, player_id: int) -> void:
	# Client plays pickup effect and removes visual
	# TODO: Integrate with existing orb system
	pass

func _schedule_orb_removal(orb_id: int, delay: float) -> void:
	await get_tree().create_timer(delay).timeout
	_orbs.erase(orb_id)

func check_magnet_pickup(player_id: int, player_position: Vector2, authoritative_world: AuthoritativeWorld) -> void:
	if not multiplayer.is_server():
		return

	# Check all unclaimed orbs for magnet range
	for orb_id in _orbs:
		var orb := _orbs[orb_id] as OrbState
		if orb.claimed:
			continue

		var distance := player_position.distance_to(orb.position)
		if distance <= MAGNET_RADIUS:
			# Move orb toward player (simple lerp for now)
			var direction := (player_position - orb.position).normalized()
			var magnet_speed: float = 300.0
			orb.position += direction * magnet_speed * 0.016  # Assume 60fps

			# Try automatic pickup if within pickup radius
			if distance <= DEFAULT_PICKUP_RADIUS:
				try_claim_orb(player_id, orb_id, player_position)

func get_orb_count() -> int:
	return _orbs.size()

func get_unclaimed_orb_count() -> int:
	var count := 0
	for orb_id in _orbs:
		var orb := _orbs[orb_id] as OrbState
		if not orb.claimed:
			count += 1
	return count

func reset() -> void:
	_orbs.clear()
	_next_orb_id = 1
