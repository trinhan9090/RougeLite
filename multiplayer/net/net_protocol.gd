class_name NetProtocol
extends Node
## Protocol versioning and message (de)serialization helpers.
## All RPC messages should use these structs for consistent encoding.

const MAX_STRING_LENGTH: int = 256
const MAX_ARRAY_LENGTH: int = 1024

static func serialize_dict(data: Dictionary) -> PackedByteArray:
	var json_string := JSON.stringify(data)
	return json_string.to_utf8_buffer()

static func deserialize_dict(data: PackedByteArray) -> Dictionary:
	var json_string := data.get_string_from_utf8()
	var json := JSON.new()
	var err := json.parse(json_string)
	if err != OK:
		push_error("NetProtocol: Failed to parse message: %s" % json.get_error_message())
		return {}
	return json.data as Dictionary

static func make_message(kind: StringName, payload: Dictionary, sender_id: int = 0) -> Dictionary:
	return {
		"kind": String(kind),
		"sender_id": sender_id,
		"timestamp": Time.get_ticks_msec(),
		"payload": payload
	}

static func validate_message(msg: Dictionary) -> bool:
	if not msg.has("kind") or not msg.has("payload") or not msg.has("sender_id"):
		return false
	if not msg.kind is String:
		return false
	if not msg.payload is Dictionary:
		return false
	return true

## Connection handshake
static func make_handshake_message(protocol_version: String, requested_character: StringName, peer_name: String) -> Dictionary:
	return make_message(&"handshake", {
		"protocol_version": protocol_version,
		"character_id": String(requested_character),
		"peer_name": peer_name.substr(0, MAX_STRING_LENGTH)
	}, 0)

static func make_handshake_ack(player_id: int, accepted: bool, reason: String) -> Dictionary:
	return make_message(&"handshake_ack", {
		"player_id": player_id,
		"accepted": accepted,
		"reason": reason
	}, 0)

## Peer state updates
static func make_peer_joined(player_id: int, character_id: StringName) -> Dictionary:
	return make_message(&"peer_joined", {
		"player_id": player_id,
		"character_id": String(character_id)
	}, 0)

static func make_peer_left(player_id: int) -> Dictionary:
	return make_message(&"peer_left", {
		"player_id": player_id
	}, 0)
