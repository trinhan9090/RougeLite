class_name RunRoot
extends Node
## Composition root for future run services. No combat, progression or RNG in UI.

signal foundation_started(summary: String)
const DEFAULT_PREVIEW_SEED: int = 20261015
var state: RunState

func _ready() -> void:
	start_foundation(DEFAULT_PREVIEW_SEED)

func start_foundation(run_seed: int) -> void:
	var registry := get_node("/root/ContentRegistry") as ContentRegistryService
	state = RunState.new(run_seed, registry.content_version())
	foundation_started.emit(state.debug_summary())
	print("RUN_FOUNDATION seed=%d content=%s" % [state.seed, state.content_version])
