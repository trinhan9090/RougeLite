extends Control
## Multiplayer host/join UI. Allows starting a host session or connecting to one.

signal host_requested()
signal join_requested(address: String, port: int)
signal back_to_menu()

@onready var host_button: Button = $CenterContainer/VBoxContainer/HostButton
@onready var join_button: Button = $CenterContainer/VBoxContainer/JoinContainer/JoinButton
@onready var back_button: Button = $CenterContainer/VBoxContainer/BackButton
@onready var address_input: LineEdit = $CenterContainer/VBoxContainer/JoinContainer/AddressInput
@onready var port_input: LineEdit = $CenterContainer/VBoxContainer/JoinContainer/PortInput
@onready var status_label: Label = $CenterContainer/VBoxContainer/StatusLabel
@onready var local_address_label: Label = $CenterContainer/VBoxContainer/LocalAddressLabel

func _ready() -> void:
	host_button.pressed.connect(_on_host_pressed)
	join_button.pressed.connect(_on_join_pressed)
	back_button.pressed.connect(_on_back_pressed)

	# Set default values
	address_input.text = "127.0.0.1"
	port_input.text = "24567"
	local_address_label.text = "Your addresses: %s" % _local_addresses()

func _on_host_pressed() -> void:
	set_status("Starting host...")
	disable_buttons(true)
	host_requested.emit()

func _on_join_pressed() -> void:
	var address := address_input.text.strip_edges()
	var port := port_input.text.to_int()

	if address.is_empty():
		set_status("Error: Address cannot be empty", true)
		return

	if port <= 0 or port > 65535:
		set_status("Error: Invalid port number", true)
		return

	set_status("Connecting to %s:%d..." % [address, port])
	disable_buttons(true)
	join_requested.emit(address, port)

func _on_back_pressed() -> void:
	back_to_menu.emit()

func set_status(message: String, is_error: bool = false) -> void:
	status_label.text = message
	status_label.add_theme_color_override("font_color", Color("ff8a80") if is_error else Color("e8eef7"))

func disable_buttons(disabled: bool) -> void:
	host_button.disabled = disabled
	join_button.disabled = disabled

func on_connection_success() -> void:
	set_status("Connected successfully!")
	# Transition to character selection or lobby
	await get_tree().create_timer(1.0).timeout
	# TODO: Load character selection scene

func on_connection_failed(reason: String) -> void:
	set_status("Connection failed: %s" % reason, true)
	disable_buttons(false)

func on_host_started() -> void:
	set_status("Host started! Waiting for players...")

## Human readable local IPv4 list so the host can share the right address.
func _local_addresses() -> String:
	var found: PackedStringArray = PackedStringArray()
	for address: String in IP.get_local_addresses():
		if address.contains(".") and not address.begins_with("127."):
			if not found.has(address):
				found.append(address)
	if found.is_empty():
		return "no LAN address detected - use a VPN IP"
	return ", ".join(found)
