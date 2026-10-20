class_name ReviveAuthority
extends Node
## Host-authoritative player revive system via F-hold interaction.
## Reviver combat abilities blocked during channel; vulnerable to damage.

signal revive_started(reviver_id: int, target_id: int)
signal revive_progress(reviver_id: int, target_id: int, progress: float)
signal revive_cancelled(reviver_id: int, target_id: int, reason: String)
signal revive_completed(reviver_id: int, target_id: int)

const DEFAULT_REVIVE_RANGE: float = 80.0
const DEFAULT_REVIVE_DURATION: float = 4.0
const DEFAULT_REVIVE_HP_FRACTION: float = 0.3

var _active_revives: Dictionary = {}  # reviver_id → ReviveState

class ReviveState:
	var reviver_id: int
	var target_id: int
	var start_tick: int
	var duration: float
	var elapsed: float = 0.0
	var is_active: bool = true

func request_revive(reviver_id: int, target_id: int) -> bool:
	if not multiplayer.is_server():
		return false

	# Check if reviver is already reviving
	if _active_revives.has(reviver_id):
		return false

	# Validate target is downed
	# TODO: Query AuthoritativeWorld
	var target_alive := true  # Placeholder
	if target_alive:
		return false

	# Validate range
	# TODO: Get actual positions from AuthoritativeWorld
	var distance: float = 50.0  # Placeholder
	if distance > DEFAULT_REVIVE_RANGE:
		return false

	# Start revive
	var revive := ReviveState.new()
	revive.reviver_id = reviver_id
	revive.target_id = target_id
	revive.start_tick = Time.get_ticks_msec()
	revive.duration = DEFAULT_REVIVE_DURATION

	_active_revives[reviver_id] = revive

	revive_started.emit(reviver_id, target_id)
	print("ReviveAuthority: Player %d started reviving player %d" % [reviver_id, target_id])

	# Broadcast to clients
	rpc("_client_receive_revive_start", reviver_id, target_id)

	# Block reviver's combat abilities
	_block_reviver_combat(reviver_id, true)

	return true

@rpc("authority", "reliable")
func _client_receive_revive_start(reviver_id: int, target_id: int) -> void:
	# Client shows revive UI/progress bar
	pass

func cancel_revive(reviver_id: int, reason: String) -> void:
	if not multiplayer.is_server():
		return

	var revive := _active_revives.get(reviver_id) as ReviveState
	if revive == null:
		return

	var target_id := revive.target_id
	_active_revives.erase(reviver_id)

	revive_cancelled.emit(reviver_id, target_id, reason)
	print("ReviveAuthority: Revive cancelled - %s" % reason)

	# Unblock reviver's combat abilities
	_block_reviver_combat(reviver_id, false)

	# Broadcast to clients
	rpc("_client_receive_revive_cancel", reviver_id, target_id, reason)

@rpc("authority", "reliable")
func _client_receive_revive_cancel(reviver_id: int, target_id: int, reason: String) -> void:
	# Client hides revive UI
	pass

func _physics_process(delta: float) -> void:
	if not multiplayer.is_server():
		return

	var to_remove: Array[int] = []

	for reviver_id in _active_revives:
		var revive := _active_revives[reviver_id] as ReviveState
		revive.elapsed += delta

		# Check cancellation conditions
		if not _validate_revive_conditions(revive):
			to_remove.append(reviver_id)
			continue

		# Update progress
		var progress := revive.elapsed / revive.duration
		revive_progress.emit(reviver_id, revive.target_id, progress)

		# Check completion
		if revive.elapsed >= revive.duration:
			_complete_revive(revive)
			to_remove.append(reviver_id)

	# Clean up completed/cancelled revives
	for reviver_id in to_remove:
		var revive := _active_revives[reviver_id] as ReviveState
		if revive.elapsed >= revive.duration:
			pass  # Already completed
		else:
			cancel_revive(reviver_id, "Conditions failed")

func _validate_revive_conditions(revive: ReviveState) -> bool:
	# TODO: Check actual game state
	# - Reviver still alive
	# - Target still downed
	# - Distance within range
	# - F key still held (input check)
	# - Reviver not CCed/knocked back
	return true

func _complete_revive(revive: ReviveState) -> void:
	_active_revives.erase(revive.reviver_id)

	# Restore target HP
	var restore_hp := int(100 * DEFAULT_REVIVE_HP_FRACTION)  # TODO: Use actual max HP
	# TODO: Apply via AuthoritativeWorld

	revive_completed.emit(revive.reviver_id, revive.target_id)
	print("ReviveAuthority: Player %d revived player %d" % [revive.reviver_id, revive.target_id])

	# Unblock reviver's combat abilities
	_block_reviver_combat(revive.reviver_id, false)

	# Broadcast to clients
	rpc("_client_receive_revive_complete", revive.reviver_id, revive.target_id)

@rpc("authority", "reliable")
func _client_receive_revive_complete(reviver_id: int, target_id: int) -> void:
	# Client plays revive effects
	pass

func _block_reviver_combat(reviver_id: int, blocked: bool) -> void:
	# TODO: Signal to SkillController to block J/K/L/I and basic attack
	# Existing projectiles/DoTs continue; new attacks suppressed
	pass

func is_reviving(player_id: int) -> bool:
	return _active_revives.has(player_id)

func get_revive_progress(player_id: int) -> float:
	var revive := _active_revives.get(player_id) as ReviveState
	if revive == null:
		return 0.0
	return revive.elapsed / revive.duration

func reset() -> void:
	_active_revives.clear()
