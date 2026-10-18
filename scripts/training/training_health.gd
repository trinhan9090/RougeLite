class_name TrainingHealth
extends Health
## Training-only health policy. Real damage is still calculated by DamageResolver.
func commit_resolved_hp(_new_hp: float) -> void:
	current = maximum
	changed.emit(current,maximum)
