## 光锥边界检测（M1-3机制就位，本次无完整关卡）
## 挂载到 Area2D 节点，检测玩家是否超出未来光锥区域
extends Area2D


## 超出光锥后冻结时间（秒）
const FREEZE_DURATION: float = 3.0

## 冻结期间画面灰白
var _frozen: bool = false
var _timer: float = 0.0
var _player: Player = null
var _reset_position: Vector2 = Vector2.ZERO


func _ready() -> void:
	body_exited.connect(_on_body_exited)
	body_entered.connect(_on_body_entered)


func _on_body_exited(body: Node2D) -> void:
	if _frozen or not body is Player:
		return
	_player = body as Player
	_reset_position = _player.get_last_safe_position()
	_frozen = true
	_timer = FREEZE_DURATION
	_player.set_frozen(true)


func _on_body_entered(body: Node2D) -> void:
	if body is Player and _frozen and body == _player:
		_reset_freeze()


func _process(delta: float) -> void:
	if not _frozen:
		return
	_timer -= delta
	if _timer <= 0.0:
		_reset_freeze()


func _reset_freeze() -> void:
	_frozen = false
	_timer = 0.0
	if _player:
		_player.set_frozen(false)
		# 重置回光锥内安全位置
		_player.global_position = _reset_position
		_player = null
