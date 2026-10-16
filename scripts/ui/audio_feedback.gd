class_name AudioFeedback
extends Node
var enabled: bool = true
var _player: AudioStreamPlayer
var _hit: AudioStreamWAV
var _kill: AudioStreamWAV
func _ready() -> void:
	_player = AudioStreamPlayer.new()
	_player.max_polyphony = 8
	_player.volume_db = -27
	add_child(_player)
	_hit = tone(500,.045)
	_kill = tone(800,.1)
func tone(frequency: float,duration: float) -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 22050
	var data := PackedByteArray()
	data.resize(roundi(22050*duration)*2)
	for i in range(data.size()/2): data.encode_s16(i*2,roundi(sin(TAU*frequency*i/22050.0)*8000*(1-i/float(data.size()/2))))
	stream.data = data
	return stream
func on_damage(_context: CombatContext,result: DamageResult) -> void:
	# A headless run has no audible output; avoid creating dummy-driver playbacks.
	if not enabled or DisplayServer.get_name() == "headless" or not result.accepted: return
	_player.stream = _kill if result.killed else _hit
	_player.play()

func _exit_tree() -> void:
	if is_instance_valid(_player):
		_player.stop()
		_player.stream = null
	_hit = null
	_kill = null
