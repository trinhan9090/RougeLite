extends SceneTree
## Negative fixture: used only when explicitly selected by harness verification.

func _initialize() -> void:
	var actual: int = 1
	var expected: int = 2
	var failed: bool = actual != expected
	if failed:
		printerr("FAIL intentional assertion: expected 2, got 1")
	print("RESULT deliberate fixture: checks=1 failures=%d" % (1 if failed else 0))
	quit(1 if failed else 0)
