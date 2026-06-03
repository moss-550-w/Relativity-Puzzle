extends "res://scenes/world_1_lorentz/level_base.gd"
## 世界 4 底层 — "本源静止空间"
##
## 时间完全不流动。过去/现在/未来同时可视。
## 独白字幕随时间浮现，停留越久越接近「本源顿悟」结局。


var _idle_time: float = 0.0
var _monologue_index: int = 0
var _monologue_shown: Array[int] = []
var _monologue_label: Label = null
var _ending_triggered: bool = false
var _wheeler_unlocked: bool = false
var _illusion_unlocked: bool = false

const MONOLOGUES: Array[Dictionary] = [
	{ "time": 10.0, "text": "时间不流动。过去和未来早已同在。" },
	{ "time": 30.0, "text": "你的一路——加速、减速、回溯——都只是视角的切换。" },
	{ "time": 60.0, "text": "惠勒-德维特方程中，时间消失了。也许它从未存在过。" },
	{ "time": 90.0, "text": "你的结局已由你一路的选择写好。闭上眼睛，看看时间的真面目。" },
]


func _get_hints() -> Array:
	return [
		{"text": "过去、现在、未来——同时存在于你眼前", "pos": Vector2(300, 500)},
		{"text": "静静观察。时间只是一幅已完成的画卷", "pos": Vector2(600, 480)},
	]


func _on_level_ready() -> void:
	GameState.double_jump_unlocked = true
	EntropySystem.pause_entropy(true)
	TimeManager.gravity_factor = 1.0
	_create_monologue_label()


func _create_monologue_label() -> void:
	var cl := CanvasLayer.new()
	cl.name = "MonologueLayer"
	cl.layer = 8

	_monologue_label = Label.new()
	_monologue_label.name = "Monologue"
	_monologue_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_monologue_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_monologue_label.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_monologue_label.position = Vector2(0, -80)
	_monologue_label.size = Vector2(900, 60)
	_monologue_label.add_theme_font_size_override("font_size", 22)
	_monologue_label.add_theme_color_override("font_color", Color(1, 1, 1, 0))
	_monologue_label.text = ""
	cl.add_child(_monologue_label)
	add_child(cl)


func _process(delta: float) -> void:
	if _level_done or _ending_triggered:
		return

	_idle_time += delta
	PlayerMetrics.bottom_layer_idle_time = _idle_time

	_check_monologues()
	_check_codex_unlocks()
	_check_ending()


func _check_monologues() -> void:
	for i in MONOLOGUES.size():
		if i in _monologue_shown:
			continue
		if _idle_time >= MONOLOGUES[i]["time"]:
			_monologue_shown.append(i)
			_show_monologue(MONOLOGUES[i]["text"])


func _show_monologue(text: String) -> void:
	_monologue_label.text = text
	_monologue_label.modulate = Color(1, 1, 1, 0)
	var tw := create_tween()
	tw.tween_property(_monologue_label, "modulate", Color(1, 1, 1, 0.85), 2.0)
	tw.tween_interval(5.0)
	tw.tween_property(_monologue_label, "modulate", Color(1, 1, 1, 0.0), 3.0)


func _check_codex_unlocks() -> void:
	if _idle_time > 60.0 and not _wheeler_unlocked:
		_wheeler_unlocked = true
		CodexManager.unlock("wheeler_dewitt")
	if _idle_time > 90.0 and not _illusion_unlocked:
		_illusion_unlocked = true
		CodexManager.unlock("time_illusion")


func _check_ending() -> void:
	if _idle_time < 120.0:
		return
	_ending_triggered = true
	var ending: int = PlayerMetrics.determine_ending()

	if _player and _player.has_method("set_frozen"):
		_player.set_frozen(true)

	# 显示结局
	var ending_text: String
	match ending:
		PlayerMetrics.Ending.SOURCE_INSIGHT:
			ending_text = "[ 本源顿悟 ]\n\n时间从未流动。\n你终于理解了。"
		PlayerMetrics.Ending.CLOSED_LOOP_PRISON:
			ending_text = "[ 闭环囚笼 ]\n\n你执着于回溯过去，\n却被困在了因果的循环之中。"
		_:
			ending_text = "[ 奔赴未来 ]\n\n你选择向前。\n未来永远是开放的。"

	var msg := Label.new()
	msg.text = ending_text
	msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	msg.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	msg.set_anchors_preset(Control.PRESET_FULL_RECT)
	msg.add_theme_font_size_override("font_size", 36)
	msg.add_theme_color_override("font_color", Color.GOLD)

	var layer := CanvasLayer.new()
	layer.layer = 100
	layer.add_child(msg)
	add_child(layer)
