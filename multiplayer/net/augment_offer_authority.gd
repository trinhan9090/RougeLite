class_name AugmentOfferAuthority
extends Node
## Host-authoritative per-player augment offer queuing, validation, and application.
## No global pause; offers queue during gameplay; death preserves pending offers.

signal offer_queued(player_id: int, offer_id: String, level_earned: int)
signal offer_accepted(player_id: int, offer_id: String, chosen_option: Dictionary)
signal offer_rejected(player_id: int, offer_id: String, reason: String)

var _player_offers: Dictionary = {}  # player_id → Array[OfferState]
var _next_offer_id: int = 1

const MAX_OFFER_OPTIONS: int = 3

class OfferState:
	var offer_id: String
	var player_id: int
	var level_earned: int
	var options: Array[Dictionary] = []  # [{aug_id, rank, type}, ...]
	var status: String = "pending"  # pending, accepted, rejected
	var created_tick: int
	var offer_seq: int

func queue_offer_for_player(player_id: int, level_earned: int, options: Array[Dictionary]) -> String:
	if not multiplayer.is_server():
		push_error("AugmentOfferAuthority: Only server can queue offers")
		return ""

	var offer_id := "offer_%d_%d" % [player_id, _next_offer_id]
	_next_offer_id += 1

	var offer := OfferState.new()
	offer.offer_id = offer_id
	offer.player_id = player_id
	offer.level_earned = level_earned
	offer.options = options.duplicate(true)
	offer.created_tick = Time.get_ticks_msec()
	offer.offer_seq = _get_next_offer_seq(player_id)

	if not _player_offers.has(player_id):
		_player_offers[player_id] = []

	_player_offers[player_id].append(offer)

	offer_queued.emit(player_id, offer_id, level_earned)

	# Send to client
	var peer_id := _get_peer_id_for_player(player_id)
	if peer_id > 0:
		rpc_id(peer_id, "_client_receive_offer", offer_id, level_earned, options)

	return offer_id

@rpc("authority", "reliable")
func _client_receive_offer(offer_id: String, level_earned: int, options: Array[Dictionary]) -> void:
	# Client shows offer UI
	# TODO: Integrate with existing upgrade picker system
	pass

func try_accept_offer(player_id: int, offer_id: String, chosen_option: Dictionary, request_id: String) -> Dictionary:
	if not multiplayer.is_server():
		return {"accepted": false, "reason": "Not server"}

	var offers := _player_offers.get(player_id, []) as Array
	var offer := _find_offer(offers, offer_id)

	if offer == null:
		return {"accepted": false, "reason": "Offer not found"}

	if offer.status != "pending":
		return {"accepted": false, "reason": "Offer already processed"}

	# Validate chosen option exists in offer
	var option_valid := false
	var validated_option: Dictionary = {}
	for opt in offer.options:
		if opt.aug_id == chosen_option.aug_id and opt.rank == chosen_option.rank:
			option_valid = true
			validated_option = opt
			break

	if not option_valid:
		return {"accepted": false, "reason": "Invalid option"}

	# Re-validate eligibility (progression may have changed)
	# TODO: Call existing EligibilityEvaluator
	var eligibility_check := _revalidate_option(player_id, validated_option)
	if not eligibility_check.valid:
		# Offer needs refresh
		offer_rejected.emit(player_id, offer_id, "Option no longer eligible")
		_refresh_offer(player_id, offer)
		return {"accepted": false, "reason": "Option no longer eligible, offer refreshed"}

	# Accept and apply
	offer.status = "accepted"
	offer_accepted.emit(player_id, offer_id, validated_option)

	# Apply augment to player (TODO: integrate with AugmentManager)
	_apply_augment_to_player(player_id, validated_option)

	# Remove from queue
	_remove_offer_from_queue(player_id, offer_id)

	# If more offers pending, send next one
	_send_next_pending_offer(player_id)

	return {"accepted": true, "reason": ""}

func _find_offer(offers: Array, offer_id: String) -> OfferState:
	for offer in offers:
		var o := offer as OfferState
		if o.offer_id == offer_id:
			return o
	return null

func _revalidate_option(player_id: int, option: Dictionary) -> Dictionary:
	# TODO: Call existing eligibility system
	# For now, assume valid
	return {"valid": true}

func _apply_augment_to_player(player_id: int, option: Dictionary) -> void:
	# TODO: Integrate with existing AugmentManager
	print("AugmentOfferAuthority: Applied augment %s rank %d to player %d" % [option.aug_id, option.rank, player_id])

func _refresh_offer(player_id: int, offer: OfferState) -> void:
	# Regenerate options for this level
	# TODO: Call OfferGenerator
	pass

func _remove_offer_from_queue(player_id: int, offer_id: String) -> void:
	if not _player_offers.has(player_id):
		return
	var offers := _player_offers[player_id] as Array
	for i in range(offers.size()):
		var o := offers[i] as OfferState
		if o.offer_id == offer_id:
			offers.remove_at(i)
			break

func _send_next_pending_offer(player_id: int) -> void:
	var offers := _player_offers.get(player_id, []) as Array
	if offers.is_empty():
		return

	var next_offer := offers[0] as OfferState
	if next_offer.status == "pending":
		var peer_id := _get_peer_id_for_player(player_id)
		if peer_id > 0:
			rpc_id(peer_id, "_client_receive_offer", next_offer.offer_id, next_offer.level_earned, next_offer.options)

func get_pending_offer_count(player_id: int) -> int:
	var offers := _player_offers.get(player_id, []) as Array
	var count := 0
	for offer in offers:
		var o := offer as OfferState
		if o.status == "pending":
			count += 1
	return count

func has_pending_offers(player_id: int) -> bool:
	return get_pending_offer_count(player_id) > 0

func clear_player_offers(player_id: int) -> void:
	_player_offers.erase(player_id)

func _get_next_offer_seq(player_id: int) -> int:
	var offers := _player_offers.get(player_id, []) as Array
	return offers.size()

func _get_peer_id_for_player(player_id: int) -> int:
	# TODO: Query SessionManager
	return -1

func reset() -> void:
	_player_offers.clear()
	_next_offer_id = 1
