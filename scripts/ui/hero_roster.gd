class_name HeroRoster
extends RefCounted
## Shared roster order, loadout mapping and class labels for presentation.
##
## This helper only describes how the six heroes are presented (order, label,
## loadout id). Character data (stats, skills, art, balance) stays untouched in
## content/ and is never edited from here.

## Display order used by the character hub and the roster page.
const ORDER: Array[String] = ["astra", "vex", "boros", "viridian", "graveshade", "tofu"]

## Hero key -> content loadout id.
const LOADOUTS: Dictionary = {
	"astra": &"loadout.astra",
	"vex": &"loadout.vex",
	"boros": &"loadout.boros",
	"viridian": &"loadout.viridian",
	"graveshade": &"loadout.graveshade",
	"tofu": &"loadout.tofu",
}

## Content class id -> player facing class label.
const CLASS_LABELS: Dictionary = {
	&"brute": "BRUISER",
	&"mage": "MAGE",
	&"adc": "ADC",
}

static func loadout_for(hero: String) -> StringName:
	return StringName(LOADOUTS.get(hero, &"loadout.astra"))

static func hero_for(loadout_id: StringName) -> String:
	for hero: String in LOADOUTS:
		if StringName(LOADOUTS[hero]) == loadout_id:
			return hero
	return ORDER[0]

static func class_label(class_id: StringName) -> String:
	return String(CLASS_LABELS.get(class_id, String(class_id).to_upper()))

## Short hero name for compact cards (drops the " - Tactical Suppressor" tail).
static func short_name(display_name: String) -> String:
	var text := display_name.strip_edges()
	for separator in [" - ", " — ", " – "]:
		var index := text.find(separator)
		if index > 0:
			return text.substr(0, index).strip_edges()
	return text
