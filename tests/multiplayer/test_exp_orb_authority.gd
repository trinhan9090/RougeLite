extends GutTest
## Tests for ExpOrbAuthority - atomic orb claiming, no double claims.

var exp_orb_authority: ExpOrbAuthority
var authoritative_world: AuthoritativeWorld

func before_each() -> void:
	# Mock server environment
	var peer := ENetMultiplayerPeer.new()
	peer.create_server(24567, 3)
	multiplayer.multiplayer_peer = peer

	exp_orb_authority = ExpOrbAuthority.new()
	authoritative_world = AuthoritativeWorld.new()
	add_child_autofree(exp_orb_authority)
	add_child_autofree(authoritative_world)

func after_each() -> void:
	multiplayer.multiplayer_peer = null

func test_spawn_orb_creates_orb() -> void:
	var orb_id := exp_orb_authority.spawn_orb(Vector2(100, 100), 10)
	assert_gt(orb_id, 0, "Should return valid orb ID")
	assert_eq(exp_orb_authority.get_orb_count(), 1, "Should have 1 orb")

func test_claim_orb_within_range() -> void:
	var orb_id := exp_orb_authority.spawn_orb(Vector2(100, 100), 10)
	var claimed := exp_orb_authority.try_claim_orb(1, orb_id, Vector2(110, 100))
	assert_true(claimed, "Should claim orb within range")
	assert_eq(exp_orb_authority.get_unclaimed_orb_count(), 0, "No unclaimed orbs remain")

func test_claim_orb_outside_range_fails() -> void:
	var orb_id := exp_orb_authority.spawn_orb(Vector2(100, 100), 10)
	var claimed := exp_orb_authority.try_claim_orb(1, orb_id, Vector2(300, 300))
	assert_false(claimed, "Should not claim orb outside range")
	assert_eq(exp_orb_authority.get_unclaimed_orb_count(), 1, "Orb remains unclaimed")

func test_double_claim_prevented() -> void:
	var orb_id := exp_orb_authority.spawn_orb(Vector2(100, 100), 10)
	exp_orb_authority.try_claim_orb(1, orb_id, Vector2(105, 105))
	var second_claim := exp_orb_authority.try_claim_orb(2, orb_id, Vector2(105, 105))
	assert_false(second_claim, "Second player should not claim already-claimed orb")

func test_invalid_orb_id_fails() -> void:
	var claimed := exp_orb_authority.try_claim_orb(1, 999, Vector2(100, 100))
	assert_false(claimed, "Should not claim non-existent orb")
