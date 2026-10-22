extends SceneTree
## Each suite is an isolated Godot process; exit code and diagnostics checked.

const SUITES: Array[String] = [
	"res://tests/integration/test_ground_zone_selection.gd",
	"res://tests/integration/test_ground_zone_targeting.gd",
	"res://tests/integration/test_tofu.gd",
	"res://tests/integration/test_doom_intro.gd",
	"res://tests/integration/test_graveshade.gd",
	"res://tests/integration/test_viridian.gd",
	"res://tests/integration/test_training_ui.gd",
	"res://tests/integration/test_training.gd",
	"res://tests/integration/test_fullscreen_attack_aim.gd",
	"res://tests/integration/test_roster_corrections.gd",
	"res://tests/integration/test_roster_pixel.gd",
	"res://tests/integration/test_torso_hurtbox.gd",
	"res://tests/integration/test_astra_cast_corrections.gd",
	"res://tests/integration/test_pixel_v3.gd",
	"res://tests/integration/test_astra_celestial_vfx.gd",
	"res://tests/integration/test_art_maps.gd",
	"res://tests/integration/test_art_vfx.gd",
	"res://tests/integration/test_art_frames.gd",
	"res://tests/unit/test_localization.gd",
	"res://tests/integration/test_boros_visual.gd",
	"res://tests/integration/test_sprite_visual.gd",
	"res://tests/integration/test_aiming.gd",
	"res://tests/integration/test_enemy_navigation.gd",
	"res://tests/unit/test_content.gd",
	"res://tests/unit/test_rng.gd",
	"res://tests/unit/test_settings.gd",
	"res://tests/scenes/test_boot.gd",
	"res://tests/integration/test_movement.gd",
	"res://tests/integration/test_actors.gd",
	"res://tests/unit/test_targeting.gd",
	"res://tests/unit/test_damage.gd",
	"res://tests/integration/test_attacks.gd",
	"res://tests/unit/test_progression.gd",
	"res://tests/unit/test_upgrades.gd",
	"res://tests/scenes/test_combat_run.gd",
	"res://tests/unit/test_skill_lifecycle.gd",
	"res://tests/integration/test_cast_modes.gd",
	"res://tests/integration/test_universal_augments.gd",
	"res://tests/integration/test_augment_combinations.gd",
	"res://tests/unit/test_bound_offers.gd",
	"res://tests/scenes/test_m2_run.gd",
	"res://tests/unit/test_event_envelope.gd",
	"res://tests/integration/test_shared_effect_matrix.gd",
	"res://tests/integration/test_full_kits.gd",
	"res://tests/integration/test_kit_edges.gd",
	"res://tests/integration/test_maps_and_bosses.gd",
	"res://tests/integration/test_endless_loop.gd",
	"res://tests/scenes/test_hazards.gd",
]

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var selected_suites: Array[String] = SUITES.duplicate()
	if OS.get_cmdline_user_args().has("--deliberate-failure"):
		selected_suites = ["res://tests/fixtures/deliberate_failure.gd"]
	var failed: int = 0
	for suite in selected_suites:
		print("RUN_SUITE ",suite)
		var output: Array = []
		var arguments := PackedStringArray(["--headless", "--path", ProjectSettings.globalize_path("res://"), "--script", suite])
		var code: int = OS.execute(OS.get_executable_path(), arguments, output, true)
		var combined: String = "\n".join(output)
		print(combined)
		if code != 0 or not combined.contains("failures=0") or combined.contains("ERROR:") or combined.contains("WARNING:") or combined.contains("SCRIPT ERROR:"):
			failed += 1
			printerr("FAIL suite=%s exit=%d" % [suite, code])
	print("RESULT suites=%d failures=%d" % [selected_suites.size(), failed])
	quit(0 if failed == 0 else 1)
