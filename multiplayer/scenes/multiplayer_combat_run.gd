extends Node2D
## Multiplayer combat scene.
##
## Runs the normal single-player combat composition (CombatRunRoot) so movement,
## skills, HUD and the Esc pause/settings menu all work, and mirrors other
## players as lightweight ghost actors using position replication.
##
## Note: enemies/damage are still simulated locally per peer. Authoritative
## shared combat is not implemented yet (see docs/MULTIPLAYER_TEST_REPORT.md).

const COMBAT_RUN_SCENE := preload("res://scenes/run/combat_run.tscn")
const CHARACTER_LOADOUTS: Dictionary[StringName, StringName] = {
	&"astra": &"loadout.astra",
	&"vex": &"loadout.vex",
	&"boros": &"loadout.boros",
	&"atyu": &"loadout.atyu",
	&"viridian": &"loadout.viridian",
	&"graveshade": &"loadout.graveshade",
	&"tofu": &"loadout.tofu",
}
const POSITION_SEND_INTERVAL := 0.1

var multiplayer_coordinator: Node
var game_bridge: MultiplayerGameBridge
var combat_root: CombatRunRoot
var is_multiplayer_mode: bool = false
var local_player_id: int = -1
var selected_character: StringName = &"astra"

var _ghosts: Dictionary[int, Node2D] = {}
var _send_clock: float = 0.0

func _ready() -> void:
	print("=== MULTIPLAYER COMBAT RUN STARTING ===")
	multiplayer_coordinator = get_node_or_null("/root/MultiplayerCoordinator")
	if multiplayer_coordinator == null:
		push_error("MultiplayerCombatRun: MultiplayerCoordinator autoload not found")
		return

	is_multiplayer_mode = multiplayer_coordinator.is_multiplayer_active()
	print("MultiplayerCombatRun: is_multiplayer_mode=", is_multiplayer_mode)
	if not is_multiplayer_mode:
		push_error("MultiplayerCombatRun: No active multiplayer session")
		return

	game_bridge = MultiplayerGameBridge.new()
	add_child(game_bridge)
	game_bridge.initialize_multiplayer_session(multiplayer_coordinator.is_host(), self)

	multiplayer_coordinator.local_player_registered.connect(_on_local_player_registered)
	multiplayer_coordinator.player_left_session.connect(_on_player_left)
	multiplayer_coordinator.session_ended.connect(_on_session_ended)

	# Start the normal combat composition so the scene is immediately playable.
	combat_root = COMBAT_RUN_SCENE.instantiate() as CombatRunRoot
	combat_root.loadout_id = CHARACTER_LOADOUTS.get(selected_character, &"loadout.astra")
	add_child(combat_root)
	move_child(combat_root, 0)

	print("MultiplayerCombatRun: Registering local player")
	multiplayer_coordinator.register_local_player(selected_character, null)
	_update_debug_labels()
	print("=== MULTIPLAYER COMBAT RUN READY ===")

func _process(delta: float) -> void:
	if not is_multiplayer_mode:
		return
	if local_player_id > 0 and combat_root != null and is_instance_valid(combat_root.player):
		# Keep the network input pipeline fed (used by the authoritative world
		# and by future server-side combat integration).
		game_bridge.process_local_input(
			Input.get_vector("move_left", "move_right", "move_up", "move_down"),
			combat_root.player.facing,
			{}
		)
		_send_clock -= delta
		if _send_clock <= 0.0:
			_send_clock = POSITION_SEND_INTERVAL
			rpc("_receive_remote_position", local_player_id, combat_root.player.global_position)
	_update_debug_labels()

func _on_local_player_registered(player_id: int, character_id: StringName) -> void:
	local_player_id = player_id
	# The host receives its own `player_joined_session` while registering, so a
	# ghost for the local player may already exist. Remove it.
	_remove_ghost(player_id)
	if combat_root != null and is_instance_valid(combat_root.player):
		game_bridge.register_player_actor(player_id, character_id, combat_root.player, true)
	print("MultiplayerCombatRun: Local player %d ready" % player_id)

func _on_player_left(player_id: int) -> void:
	_remove_ghost(player_id)

func _remove_ghost(player_id: int) -> void:
	var ghost := _ghosts.get(player_id) as Node2D
	if ghost != null and is_instance_valid(ghost):
		ghost.queue_free()
	_ghosts.erase(player_id)

func _on_session_ended() -> void:
	is_multiplayer_mode = false
	local_player_id = -1

@rpc("any_peer", "unreliable_ordered")
func _receive_remote_position(player_id: int, position: Vector2) -> void:
	if player_id == local_player_id or player_id < 0:
		return
	var ghost := _ghosts.get(player_id) as Node2D
	if ghost == null or not is_instance_valid(ghost):
		ghost = _ensure_ghost(player_id)
	if ghost != null:
		ghost.global_position = position

func _ensure_ghost(player_id: int) -> Node2D:
	var existing := _ghosts.get(player_id) as Node2D
	if existing != null and is_instance_valid(existing):
		return existing

	var ghost := Node2D.new()
	ghost.name = "Ghost_%d" % player_id
	ghost.z_index = 5

	var body := Polygon2D.new()
	body.polygon = PackedVector2Array([
		Vector2(-14, -22), Vector2(14, -22), Vector2(14, 22), Vector2(-14, 22)
	])
	body.color = Color(0.35, 0.8, 1.0, 0.55)
	ghost.add_child(body)

	add_child(ghost)
	_ghosts[player_id] = ghost
	return ghost

func _update_debug_labels() -> void:
	var panel := get_node_or_null("UI/DebugOverlay/InfoPanel/VBoxContainer")
	if panel == null:
		return
	var role_label := panel.get_node_or_null("RoleLabel") as Label
	if role_label and multiplayer_coordinator:
		role_label.text = "Role: %s" % ("Host" if multiplayer_coordinator.is_host() else "Client")
	var id_label := panel.get_node_or_null("PlayerIDLabel") as Label
	if id_label:
		id_label.text = "Player ID: %d" % local_player_id
	var peer_label := panel.get_node_or_null("PeerCountLabel") as Label
	if peer_label and multiplayer_coordinator and multiplayer_coordinator.network_manager:
		peer_label.text = "Connected Players: %d" % multiplayer_coordinator.network_manager.get_peer_count()
	var clock_label := panel.get_node_or_null("ClockLabel") as Label
	if clock_label and multiplayer_coordinator and multiplayer_coordinator.match_clock_authority:
		clock_label.text = "Match Time: %s" % multiplayer_coordinator.match_clock_authority.get_formatted_time()

func end_session() -> void:
	if is_multiplayer_mode:
		multiplayer_coordinator.stop_session()
		is_multiplayer_mode = false
		local_player_id = -1
