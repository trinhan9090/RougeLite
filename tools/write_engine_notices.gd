extends SceneTree
func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://docs/licenses"))
	var license := FileAccess.open("res://docs/licenses/GODOT_LICENSE.txt",FileAccess.WRITE)
	license.store_string(Engine.get_license_text())
	license.close()
	var third_party := FileAccess.open("res://docs/licenses/GODOT_THIRD_PARTY.json",FileAccess.WRITE)
	third_party.store_string(JSON.stringify({"copyrights":Engine.get_copyright_info(),"licenses":Engine.get_license_info()},"\t"))
	third_party.close()
	print("Engine notices extracted from executing binary")
	quit()
