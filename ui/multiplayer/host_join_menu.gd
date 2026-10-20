extends Control

## Multiplayer host/join menu. Simple UI for LAN/VPN IP joining.

@onready var host_button: Button = $VBoxContainer/HostButton
@onready var join_button: Button = $JoinContainer/JoinButton
@onready var ip_input: LineEdit = $JoinContainer/IPInput
@onready var port_input: LineEdit = $JoinContainer/PortInput
@onready var status_label: Label = $StatusLabel

func _ready() -> void:
	host_button.pressed.connect(_on_host_pressed)
	join_button.pressed.connect(_on_join_pressed)
	ip_input.text = "127.0.0.1"
	port_input.text = "24567"
	status_label.text = "Ready to host or join"

func _on_host_pressed() -> void:
	var port := int(port_input.text)
	if port < 1024 or port > 65535:
		status_label.text = "Invalid port (1024-65535)"
		return
	var err := NetworkManager.start_host(port)
	if err == OK:
		status_label.text = "Host started on port %d" % port
		SessionManager.register_host_player()
		host_button.disabled = true
		join_button.disabled = true
	else:
		status_label.text = "Failed to host: %s" % error_string(err)

func _on_join_pressed() -> void:
	var address := ip_input.text.strip_edges()
	var port := int(port_input.text)
	if address.is_empty():
		status_label.text = "Enter IP address"
		return
	if port < 1024 or port > 65535:
		status_label.text = "Invalid port (1024-65535)"
		return
	status_label.text = "Connecting to %s:%d..." % [address, port]
	var err := NetworkManager.join_host(address, port)
	if err != OK:
		status_label.text = "Failed to join: %s" % error_string(err)
