extends GutTest
## Integration test for AugmentOfferAuthority - per-player queues, no auto-pick.

var offer_authority: AugmentOfferAuthority

func before_each() -> void:
	# Mock server
	var peer := ENetMultiplayerPeer.new()
	peer.create_server(24567, 3)
	multiplayer.multiplayer_peer = peer

	offer_authority = AugmentOfferAuthority.new()
	add_child_autofree(offer_authority)

func after_each() -> void:
	multiplayer.multiplayer_peer = null

func test_queue_offer_creates_pending_offer() -> void:
	var options: Array[Dictionary] = [
		{"aug_id": "split", "rank": 1, "type": "augment"},
		{"aug_id": "multishot", "rank": 1, "type": "augment"},
		{"aug_id": "core_hp", "rank": 1, "type": "stat"}
	]
	var offer_id := offer_authority.queue_offer_for_player(1, 3, options)
	assert_ne(offer_id, "", "Should return valid offer ID")
	assert_eq(offer_authority.get_pending_offer_count(1), 1, "Player 1 should have 1 pending offer")

func test_multiple_offers_queue_independently() -> void:
	var options: Array[Dictionary] = [
		{"aug_id": "split", "rank": 1, "type": "augment"},
		{"aug_id": "multishot", "rank": 1, "type": "augment"},
		{"aug_id": "core_hp", "rank": 1, "type": "stat"}
	]

	offer_authority.queue_offer_for_player(1, 3, options)
	offer_authority.queue_offer_for_player(1, 4, options)
	offer_authority.queue_offer_for_player(1, 5, options)

	assert_eq(offer_authority.get_pending_offer_count(1), 3, "Player 1 should have 3 queued offers")

func test_accept_valid_option() -> void:
	var options: Array[Dictionary] = [
		{"aug_id": "split", "rank": 1, "type": "augment"},
		{"aug_id": "multishot", "rank": 1, "type": "augment"},
		{"aug_id": "core_hp", "rank": 1, "type": "stat"}
	]
	var offer_id := offer_authority.queue_offer_for_player(1, 3, options)

	var chosen := {"aug_id": "split", "rank": 1, "type": "augment"}
	var result := offer_authority.try_accept_offer(1, offer_id, chosen, "req_1")

	assert_true(result.accepted, "Valid option should be accepted")
	assert_eq(offer_authority.get_pending_offer_count(1), 0, "Offer should be removed after acceptance")

func test_reject_invalid_option() -> void:
	var options: Array[Dictionary] = [
		{"aug_id": "split", "rank": 1, "type": "augment"}
	]
	var offer_id := offer_authority.queue_offer_for_player(1, 3, options)

	var invalid_chosen := {"aug_id": "invalid_aug", "rank": 99, "type": "augment"}
	var result := offer_authority.try_accept_offer(1, offer_id, invalid_chosen, "req_2")

	assert_false(result.accepted, "Invalid option should be rejected")

func test_player_2_cannot_accept_player_1_offer() -> void:
	var options: Array[Dictionary] = [
		{"aug_id": "split", "rank": 1, "type": "augment"}
	]
	var offer_id := offer_authority.queue_offer_for_player(1, 3, options)

	# Player 2 tries to accept player 1's offer (impossible via UI, but test authority)
	var chosen := {"aug_id": "split", "rank": 1, "type": "augment"}
	var result := offer_authority.try_accept_offer(2, offer_id, chosen, "req_3")

	assert_false(result.accepted, "Player 2 should not access player 1's offer")

func test_duplicate_accept_rejected() -> void:
	var options: Array[Dictionary] = [
		{"aug_id": "split", "rank": 1, "type": "augment"}
	]
	var offer_id := offer_authority.queue_offer_for_player(1, 3, options)

	var chosen := {"aug_id": "split", "rank": 1, "type": "augment"}
	offer_authority.try_accept_offer(1, offer_id, chosen, "req_4")

	# Try to accept again
	var result := offer_authority.try_accept_offer(1, offer_id, chosen, "req_5")

	assert_false(result.accepted, "Duplicate accept should be rejected")
