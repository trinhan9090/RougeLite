extends SceneTree
## Multiplayer test runner - executes all multiplayer unit and integration tests.

func _init() -> void:
	var gut := load("res://addons/gut/gut.gd").new()

	# Configure GUT
	gut.add_directory("res://tests/multiplayer")
	gut.set_log_level(gut.LOG_LEVEL_ALL_ASSERTS)
	gut.set_ignore_pause(true)
	gut.set_yield_between_tests(true)
	gut.set_export_path("res://reports/multiplayer_test_results.json")

	# Add to scene
	var root := Window.new()
	root.add_child(gut)
	root.gui_embed_subwindows = false

	# Connect signals
	gut.tests_finished.connect(_on_tests_finished)

	# Run tests
	print("=== Running Multiplayer Tests ===")
	gut.test_scripts()

func _on_tests_finished() -> void:
	var gut := get_root().get_child(0)
	var summary := gut.get_summary()

	print("\n=== Multiplayer Test Summary ===")
	print("Passed: %d" % summary.passing)
	print("Failed: %d" % summary.failing)
	print("Pending: %d" % summary.pending)
	print("Orphans: %d" % summary.orphans)
	print("================================\n")

	if summary.failing > 0:
		quit(1)
	else:
		quit(0)
