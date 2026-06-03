extends "res://scenes/world_1_lorentz/level_base.gd"
## 世界 4 上层 — "熵之斜坡"
##
## 昼夜循环 + 平台渐进崩解 + 秩序能量收集
## 玩家在熵增的倒计时中穿越崩解的世界


var _daynight_overlay: ColorRect = null


func _get_hints() -> Array:
	return [
		{"text": "世界在崩解……收集金色秩序能量延缓衰亡", "pos": Vector2(300, 500)},
		{"text": "按 [E] 消耗秩序能量暂缓脚下的崩解", "pos": Vector2(600, 480)},
		{"text": "熵不可逆——你只是在局部争取时间", "pos": Vector2(900, 420)},
	]


func _on_level_ready() -> void:
	EntropySystem.reset()
	EntropySystem.pause_entropy(false)
	GameState.double_jump_unlocked = true  # World 4 在克尔黑洞之后，确保二段跳生效
	_create_daynight_cycle()


func _create_daynight_cycle() -> void:
	var cl := CanvasLayer.new()
	cl.name = "DayNightLayer"
	cl.layer = -2

	_daynight_overlay = ColorRect.new()
	_daynight_overlay.name = "DayNightOverlay"
	_daynight_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_daynight_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_daynight_overlay.color = Color(0.35, 0.25, 0.05, 0.25)  # 初始白天暖橙
	cl.add_child(_daynight_overlay)
	add_child(cl)


## 每帧更新昼夜（由 _process 驱动，替代不可靠的 Timer）
func _process(_delta: float) -> void:
	if _level_done or not _daynight_overlay:
		return
	var t: float = Time.get_ticks_msec() / 1000.0
	var phase: float = fmod(t / 90.0, 1.0)
	# 正弦模拟昼夜：0=正午(暖橙) 0.5=午夜(深蓝) 1=正午
	var warmth: float = sin(phase * TAU) * 0.5 + 0.5
	var night: Color = Color(0.06, 0.04, 0.18, 0.55)  # 深蓝夜
	var day: Color = Color(0.4, 0.25, 0.05, 0.3)      # 暖橙昼
	_daynight_overlay.color = night.lerp(day, warmth)
