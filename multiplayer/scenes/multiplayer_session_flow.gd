extends Control
## Full multiplayer session flow: host/join -> lobby -> game.

@onready var host_join_menu: Control = $HostJoinMenu
@onready var lobby: Control = $Lobby
@onready var loading_screen: Control = $LoadingScreen
@onready var status_label: Label = $StatusLabel
@onready var lobby_back_button: Button = $Lobby/CenterContainer/VBoxContainer/LobbyBackButton
@onready var start_button: Button = $Lobby/CenterContainer/VBoxContainer/StartButton
@onready var player_list: VBoxContainer = $Lobby/CenterContainer/VBoxContainer/PlayerList

var multiplayer_coordinator: Node
var selected_character: StringName = &"astra"
## Port used when hosting; tests can override it.
var host_port: int = 24567

enum State {
	MAIN_MENU,
	LOBBY,
	LOADING_MAP,
	IN_GAME,
	GAME_OVER
}

var current_state: State = State.MAIN_MENU

func _ready() -> void:
	# Wait for coordinator autoload to be ready
	await get_tree().process_frame

	if not has_node("/root/MultiplayerCoordinator"):
		push_error("MultiplayerCoordinator autoload not found!")
		set_status("ERROR: Multiplayer system not initialized", true)
		return

	multiplayer_coordinator = get_node("/root/MultiplayerCoordinator")
	# The hero picked in the character hub travels with the coordinator.
	var chosen: Variant = multiplayer_coordinator.get("local_character")
	if chosen != null and StringName(chosen) != &"":
		selected_character = StringName(chosen)

	# Wire host/join menu
	host_join_menu.host_requested.connect(_on_host_requested)
	host_join_menu.join_requested.connect(_on_join_requested)
	host_join_menu.back_to_menu.connect(_on_back_to_menu)

	# Wire lobby buttons
	lobby_back_button.pressed.connect(_on_back_to_menu)
	start_button.pressed.connect(_on_start_pressed)

	# Wire coordinator signals
	multiplayer_coordinator.network_manager.server_started.connect(_on_server_started)
	multiplayer_coordinator.network_manager.connection_failed.connect(_on_connection_failed)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer_coordinator.session_started.connect(_on_session_started)
	multiplayer_coordinator.player_joined_session.connect(func(_player_id: int, _character_id: StringName) -> void: _refresh_player_list())
	multiplayer_coordinator.player_left_session.connect(func(_player_id: int) -> void: _refresh_player_list())
	multiplayer_coordinator.local_player_registered.connect(func(_player_id: int, _character_id: StringName) -> void: _refresh_player_list())

	# Start at host/join menu
	_show_host_join_menu()

	print("MultiplayerSessionFlow: Ready and connected to coordinator")

## Rebuild the lobby roster so the host sees who is connected.
func _refresh_player_list() -> void:
	if player_list == null:
		return
	for child in player_list.get_children():
		child.queue_free()
	var sessions: Dictionary = {}
	if multiplayer_coordinator != null and multiplayer_coordinator.session_manager != null:
		sessions = multiplayer_coordinator.session_manager.players
	if sessions.is_empty():
		var waiting := Label.new()
		waiting.text = "Waiting for players..."
		waiting.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		waiting.add_theme_font_size_override("font_size", 15)
		waiting.add_theme_color_override("font_color", Color(0.7, 0.76, 0.86, 1.0))
		player_list.add_child(waiting)
		return
	for peer_id: int in sessions:
		var session = sessions[peer_id]
		var row := Label.new()
		var character_id: String = String(session.character_id) if session.character_id != &"" else "player"
		row.text = "• %s  (peer %d)" % [character_id, int(session.player_id)]
		row.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		row.add_theme_font_size_override("font_size", 16)
		row.add_theme_color_override("font_color", Color(0.85, 0.9, 0.96, 1.0))
		player_list.add_child(row)

func _show_host_join_menu() -> void:
	current_state = State.MAIN_MENU
	host_join_menu.visible = true
	lobby.visible = false
	loading_screen.visible = false
	status_label.visible = false

func _show_lobby() -> void:
	current_state = State.LOBBY
	host_join_menu.visible = false
	lobby.visible = true
	loading_screen.visible = false
	status_label.visible = false
	start_button.disabled = false
	_refresh_player_list()

func _show_loading() -> void:
	current_state = State.LOADING_MAP
	host_join_menu.visible = false
	lobby.visible = false
	loading_screen.visible = true
	status_label.visible = false
	print("MultiplayerSessionFlow: Showing loading screen")

func _on_host_requested() -> void:
	print("Host requested...")
	set_status("Starting host...")

	var err: int = multiplayer_coordinator.start_host_session(host_port)
	print("Host start result: ", err, " (OK=", OK, ")")

	if err != OK:
		var error_msg := "Failed to start host: %s" % error_string(err)
		set_status(error_msg, true)
		host_join_menu.on_connection_failed("Could not bind port")
		push_error(error_msg)
	else:
		# Host started successfully - transition to lobby immediately
		await get_tree().create_timer(0.1).timeout
		host_join_menu.on_host_started()
		_show_lobby()

func _on_join_requested(address: String, port: int) -> void:
	set_status("Connecting to %s:%d..." % [address, port])
	var err: int = multiplayer_coordinator.join_session(address, port)
	if err != OK:
		set_status("Failed to join: %s" % error_string(err), true)
		host_join_menu.on_connection_failed("Connection error")

func _on_back_to_menu() -> void:
	print("Back to menu requested - stopping session...")
	# Force stop any active session/connection
	if multiplayer_coordinator:
		multiplayer_coordinator.stop_session()
	# Give it a moment to clean up
	await get_tree().create_timer(0.1).timeout
	# Return to main menu
	get_tree().change_scene_to_file("res://scenes/bootstrap/main.tscn")

func _on_start_pressed() -> void:
	print("Start match pressed - initializing map...")
	# Disable button to prevent multiple clicks
	start_button.disabled = true

	# Show loading screen
	_show_loading()

	# Start match (this will emit session_started when map is ready)
	multiplayer_coordinator.start_match(&"map.temple")
	print("Start match pressed - start_match() called")

func _on_server_started() -> void:
	# Already handled in _on_host_requested
	pass

func _on_connected_to_server() -> void:
	# Client successfully connected - show lobby
	print("Connected to server - showing lobby")
	_show_lobby()

func _on_connection_failed(reason: String) -> void:
	host_join_menu.on_connection_failed(reason)

func _on_session_started() -> void:
	# Match started and map loaded, transition to combat scene
	print("Session started - transitioning to IN_GAME")
	current_state = State.IN_GAME
	var err := get_tree().change_scene_to_file("res://multiplayer/scenes/multiplayer_combat_run.tscn")
	print("Scene change result: ", err)
	if err != OK:
		push_error("Failed to change scene to combat run: %s" % error_string(err))

func set_status(message: String, is_error: bool = false) -> void:
	status_label.text = message
	status_label.modulate = Color.RED if is_error else Color.WHITE
	status_label.visible = true
