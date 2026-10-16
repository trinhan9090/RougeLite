extends SceneTree
var failures: int = 0
var checks: int = 0
func _initialize() -> void: call_deferred("run_tests")
func check(value: bool,label: String) -> void:
	checks += 1
	if value: print("PASS ",label)
	else:
		failures += 1
		printerr("FAIL ",label)
func run_tests() -> void:
	TranslationServer.set_locale("vi")
	check(TranslationServer.translate("PLAY") == "CHƠI","Vietnamese menu with full diacritics")
	check(TranslationServer.translate("CHARACTER") == "NHÂN VẬT","Vietnamese character title")
	check(TranslationServer.translate("Ground Slam") == "Chấn địa","skill display translated without changing ID")
	var hud := RunHud.new()
	root.add_child(hud)
	hud.present(100,130,0,25,3,42,5,"Astra",&"MANUAL")
	check(hud._label.text.contains("Cấp 3") and hud._label.text.contains("Hạ gục 5"),"formatted Vietnamese HUD")
	check(hud._hint.text.contains("THỦ CÔNG"),"Vietnamese manual mode")
	var option := UpgradeOption.new()
	option.definition = load("res://content/augments/stats/damage.tres") as AugmentDefinition
	var original: String = option.label()
	var localized: String = UiLocalizer.upgrade_label(option)
	check(localized.contains("Sức mạnh") and localized.contains("Bậc"),"Vietnamese upgrade name and rank")
	check(option.label() == original and option.definition.id == &"stat.damage","localization preserves content and stable ID")
	TranslationServer.set_locale("en")
	check(TranslationServer.translate("PLAY") == "PLAY","English catalog retained")
	TranslationServer.set_locale("vi")
	hud.queue_free()
	await process_frame
	print("RESULT localization checks=%d failures=%d" % [checks,failures])
	quit(0 if failures == 0 else 1)
