class_name MultiplayerGameBridge
extends Node
## Integrates multiplayer systems with existing single-player combat infrastructure.
## Bridges CombatRunRoot, PlayerActor, EXP systems with authoritative multiplayer.

signal integration_ready()

var multiplayer_coordinator: MultiplayerCoordinator
var combat_run_root: Node  # Reference to existing CombatRunRoot
var is_multiplayer_session: bool = false

var _player_actor_map: Dictionary = {}  # player_id → PlayerActor node
var _local_player_id: int = -1

func _ready() -> void:
	# Get multiplayer coordinator
	multiplayer_coordinator = get_node_or_null("/root/MultiplayerCoordinator")
	if multiplayer_coordinator == null:
		push_error("MultiplayerGameBridge: MultiplayerCoordinator autoload not found")
		return

	_connect_multiplayer_signals()

func _connect_multiplayer_signals() -> void:
	if multiplayer_coordinator == null:
		return

	multiplayer_coordinator.player_joined_session.connect(_on_player_joined_session)
	multiplayer_coordinator.player_left_session.connect(_on_player_left_session)
	multiplayer_coordinator.exp_orb_authority.orb_spawned.connect(_on_orb_spawned)
	multiplayer_coordinator.exp_orb_authority.orb_claimed.connect(_on_orb_claimed)
	multiplayer_coordinator.augment_offer_authority.offer_queued.connect(_on_offer_queued)
	multiplayer_coordinator.time_encounter_director.boss_spawned.connect(_on_boss_spawned)
	multiplayer_coordinator.match_clock_authority.clock_updated.connect(_on_clock_updated)
	multiplayer_coordinator.revive_authority.revive_started.connect(_on_revive_started)
	multiplayer_coordinator.revive_authority.revive_completed.connect(_on_revive_completed)

func initialize_multiplayer_session(is_host: bool, combat_root: Node) -> void:
	is_multiplayer_session = true
	combat_run_root = combat_root

	if is_host:
		_initialize_host_session()
	else:
		_initialize_client_session()

func _initialize_host_session() -> void:
	# Host runs full authoritative simulation
	# Existing CombatRunRoot should work with minor modifications
	print("MultiplayerGameBridge: Initializing host session")
	integration_ready.emit()

func _initialize_client_session() -> void:
	# Client runs visual/prediction only
	# Disable authoritative systems, rely on server snapshots
	print("MultiplayerGameBridge: Initializing client session")
	integration_ready.emit()

func register_player_actor(player_id: int, character_id: StringName, actor: Node, is_local: bool = false) -> void:
	_player_actor_map[player_id] = actor

	# Host can detect the local player by peer id; a client has no host-side
	# roster, so the caller marks its own player explicitly.
	var local := is_local
	if multiplayer.is_server():
		local = local or multiplayer.get_unique_id() == multiplayer_coordinator.session_manager.get_peer_id_for_player(player_id)
	if local:
		_local_player_id = player_id
		# Enable prediction for local player
		multiplayer_coordinator.prediction_reconciliation.enable_prediction(true)

	# Register with authoritative world if host
	if multiplayer.is_server():
		var peer_id := multiplayer_coordinator.session_manager.get_peer_id_for_player(player_id)
		multiplayer_coordinator.authoritative_world.register_player(player_id, peer_id, character_id, actor)

func unregister_player_actor(player_id: int) -> void:
	_player_actor_map.erase(player_id)

	if multiplayer.is_server():
		multiplayer_coordinator.authoritative_world.unregister_player(player_id)

func process_local_input(movement: Vector2, aim: Vector2, actions: Dictionary) -> void:
	if not is_multiplayer_session:
		return

	if _local_player_id < 0:
		return

	# Send input to server
	multiplayer_coordinator.submit_local_input(movement, aim, actions)

func spawn_exp_orb(position: Vector2, exp_amount: int) -> void:
	if not is_multiplayer_session:
		return

	if not multiplayer.is_server():
		return  # Only host spawns orbs

	multiplayer_coordinator.exp_orb_authority.spawn_orb(position, exp_amount)

func try_claim_exp_orb(player_id: int, orb_id: int, player_position: Vector2) -> void:
	if not is_multiplayer_session:
		return

	if not multiplayer.is_server():
		return

	multiplayer_coordinator.exp_orb_authority.try_claim_orb(player_id, orb_id, player_position)

func grant_player_exp(player_id: int, exp_amount: int) -> void:
	# Integrate with existing progression system
	# TODO: Call existing RunState or progression manager
	print("MultiplayerGameBridge: Granting %d EXP to player %d" % [exp_amount, player_id])

func queue_augment_offer(player_id: int, level_earned: int) -> void:
	if not is_multiplayer_session:
		return

	if not multiplayer.is_server():
		return

	# Generate offer options using existing system
	# TODO: Call existing OfferGenerator
	var options: Array[Dictionary] = _generate_augment_options(player_id, level_earned)

	multiplayer_coordinator.augment_offer_authority.queue_offer_for_player(player_id, level_earned, options)

func _generate_augment_options(player_id: int, level: int) -> Array[Dictionary]:
	# Placeholder - TODO: integrate with existing EligibilityEvaluator and OfferGenerator
	var options: Array[Dictionary] = []

	# Example options
	options.append({"aug_id": "split", "rank": 1, "type": "augment"})
	options.append({"aug_id": "multishot", "rank": 1, "type": "augment"})
	options.append({"aug_id": "core_hp", "rank": 1, "type": "stat"})

	return options

func request_augment_choice(player_id: int, offer_id: String, chosen_option: Dictionary) -> void:
	if not is_multiplayer_session:
		return

	# Send to server for validation
	var request_id := "%d_%d" % [player_id, Time.get_ticks_msec()]
	var result := multiplayer_coordinator.augment_offer_authority.try_accept_offer(player_id, offer_id, chosen_option, request_id)

	if not result.accepted:
		push_error("MultiplayerGameBridge: Augment choice rejected: %s" % result.reason)

func apply_damage_to_player(player_id: int, amount: int, source_id: int) -> void:
	if not is_multiplayer_session:
		return

	if not multiplayer.is_server():
		return

	multiplayer_coordinator.authoritative_world.apply_damage_to_player(player_id, amount, source_id)

func apply_damage_to_enemy(enemy_id: int, amount: int, attacker_player_id: int) -> void:
	if not is_multiplayer_session:
		return

	if not multiplayer.is_server():
		return

	multiplayer_coordinator.authoritative_world.apply_damage_to_enemy(enemy_id, amount, attacker_player_id)

func start_revive(reviver_id: int, target_id: int) -> void:
	if not is_multiplayer_session:
		return

	if not multiplayer.is_server():
		return

	multiplayer_coordinator.revive_authority.request_revive(reviver_id, target_id)

func cancel_revive(reviver_id: int) -> void:
	if not is_multiplayer_session:
		return

	if not multiplayer.is_server():
		return

	multiplayer_coordinator.revive_authority.cancel_revive(reviver_id, "Player released F")

# Signal handlers for multiplayer events

func _on_player_joined_session(player_id: int, character_id: StringName) -> void:
	print("MultiplayerGameBridge: Player %d joined with character %s" % [player_id, character_id])
	# TODO: Spawn player actor in world

func _on_player_left_session(player_id: int) -> void:
	print("MultiplayerGameBridge: Player %d left" % player_id)
	unregister_player_actor(player_id)

func _on_orb_spawned(orb_id: int, position: Vector2, exp_amount: int) -> void:
	# Spawn visual orb in scene
	# TODO: Integrate with existing orb spawner
	pass

func _on_orb_claimed(orb_id: int, player_id: int, exp_amount: int) -> void:
	grant_player_exp(player_id, exp_amount)
	# TODO: Play pickup effects

func _on_offer_queued(player_id: int, offer_id: String, level_earned: int) -> void:
	# Show upgrade picker UI for this player
	if player_id == _local_player_id:
		# TODO: Open upgrade picker
		print("MultiplayerGameBridge: Show offer for local player at level %d" % level_earned)

func _on_boss_spawned(boss_id: String, boss_sequence: int, elapsed_time: float) -> void:
	# Spawn boss in world
	# TODO: Integrate with existing boss spawner
	print("MultiplayerGameBridge: Boss #%d spawned at %.2fs" % [boss_sequence, elapsed_time])

func _on_clock_updated(elapsed_seconds: float) -> void:
	# Update HUD clock display
	# TODO: Update existing HUD
	pass

func _on_revive_started(reviver_id: int, target_id: int) -> void:
	print("MultiplayerGameBridge: Revive started: %d reviving %d" % [reviver_id, target_id])
	# TODO: Show revive progress UI

func _on_revive_completed(reviver_id: int, target_id: int) -> void:
	print("MultiplayerGameBridge: Revive completed: %d revived %d" % [reviver_id, target_id])
	# TODO: Restore player state
