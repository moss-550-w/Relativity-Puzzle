extends CanvasLayer
## TransitionLayer — 场景过渡管理器
## 所有场景切换统一经此：淡出 → change_scene → 新场景 _ready 淡入


var _fade_rect: ColorRect = null
var _is_transitioning: bool = false


func _ready() -> void:
	layer = 1000
	_fade_rect = ColorRect.new()
	_fade_rect.name = "FadeRect"
	_fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade_rect.color = Color(0, 0, 0, 0)
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fade_rect)


## 带淡出过渡的场景切换
func transition_to(scene_path: String) -> void:
	if _is_transitioning:
		return
	_is_transitioning = true
	var tw := create_tween()
	tw.set_ease(Tween.EASE_IN)
	tw.tween_property(_fade_rect, "color:a", 1.0, 0.3)
	tw.tween_callback(func() -> void:
		get_tree().change_scene_to_file(scene_path)
	)


## 新场景 _ready 末尾调用，淡入画面
func fade_in() -> void:
	# 确保遮罩初始为全黑（场景切换后颜色重置）
	_fade_rect.color = Color(0, 0, 0, 1)
	var tw := create_tween()
	tw.set_ease(Tween.EASE_OUT)
	tw.tween_property(_fade_rect, "color:a", 0.0, 0.4)
	tw.tween_callback(func() -> void:
		_is_transitioning = false
	)
