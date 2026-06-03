extends Area2D
## 时空碎片 — M1-1 终点
## 玩家到达后触发图鉴解锁 + 关卡完成


@export var codex_id: String = "time_dilation"

var _triggered: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)

	# 视觉占位：金色旋转菱形
	var visual := Polygon2D.new()
	visual.name = "Visual"
	visual.color = Color.GOLD
	visual.polygon = PackedVector2Array([
		Vector2(0, -20), Vector2(16, 0),
		Vector2(0, 20), Vector2(-16, 0)
	])
	add_child(visual)


## 添加强调用脉冲动画
func _process(delta: float) -> void:
	var visual := get_node_or_null("Visual") as Polygon2D
	if visual and not _triggered:
		visual.rotation += delta * 2.0  # 原地旋转，吸引注意
		# 脉冲缩放
		var pulse := 1.0 + sin(Time.get_ticks_msec() * 0.005) * 0.15
		visual.scale = Vector2(pulse, pulse)


func _on_body_entered(body: Node2D) -> void:
	if _triggered:
		return
	if not body.is_in_group("player"):
		return

	_triggered = true

	# 动画：碎片缩小消失
	var visual := get_node_or_null("Visual") as Polygon2D
	if visual:
		var tween := create_tween()
		tween.tween_property(visual, "scale", Vector2(2.0, 2.0), 0.2)
		tween.tween_property(visual, "scale", Vector2.ZERO, 0.4)
		tween.tween_callback(visual.queue_free)

	AudioManager.play_sfx("fragment_collect")
	# 解锁图鉴（触发 HUD toast）
	CodexManager.unlock(codex_id)
	# 关卡完成
	GameState.complete_level()
