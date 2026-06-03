extends Area2D
## 时空碎片 — M1-1 终点
## 玩家到达后触发图鉴解锁 + 关卡完成

const _Player = preload("res://scripts/player/player.gd")


@export var codex_id: String = "time_dilation"

var _triggered: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)

	# 创建视觉占位：金色菱形
	var visual := Polygon2D.new()
	visual.color = Color.GOLD
	visual.polygon = PackedVector2Array([
		Vector2(0, -20), Vector2(16, 0),
		Vector2(0, 20), Vector2(-16, 0)
	])
	add_child(visual)


func _on_body_entered(body: Node2D) -> void:
	if _triggered or not (body is _Player):
		return
	_triggered = true

	# 解锁对应图鉴
	CodexManager.unlock(codex_id)
	# 关卡完成
	GameState.complete_level()
