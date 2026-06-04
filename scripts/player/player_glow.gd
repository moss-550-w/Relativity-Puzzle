extends Node2D
## PlayerGlow — 玩家速度光晕 + 技能闪色（置于 Player 子节点 VisualRoot 之前）
## 仅在 _draw 绘制柔和同心光晕，不随尺缩变形


const LIGHT_SPEED: float = 1000.0

var _speed_ratio: float = 0.0      # speed / LIGHT_SPEED  [0, 1)
var _redline_ratio: float = 0.0    # get_redline_ratio 输出 [0, 1]
var _t: float = 0.0

# 技能闪光（缓降，由 player.gd 写入）
var _flash_cyan: float = 0.0       # E 观测闪光
var _flash_orange: float = 0.0     # F 抓取闪光


func set_state(speed_ratio: float, redline_ratio: float, t: float) -> void:
	_speed_ratio = speed_ratio
	_redline_ratio = redline_ratio
	_t = t
	queue_redraw()


## 由 player.gd 调用：触发 E 键观测闪光
func trigger_observe_flash() -> void:
	_flash_cyan = 1.0


## 由 player.gd 调用：触发 F 键抓取闪光
func trigger_grab_flash() -> void:
	_flash_orange = 1.0


func _process(delta: float) -> void:
	var changed: bool = false
	if _flash_cyan > 0.0:
		_flash_cyan = maxf(0.0, _flash_cyan - delta * 4.0)
		changed = true
	if _flash_orange > 0.0:
		_flash_orange = maxf(0.0, _flash_orange - delta * 4.0)
		changed = true
	if changed:
		queue_redraw()


func _draw() -> void:
	var pos: Vector2 = Vector2.ZERO  # 以自身位置为圆心

	# 低速：微弱白光
	var white_alpha: float = 0.06 + _speed_ratio * 0.08
	if _speed_ratio < 0.5:
		white_alpha = 0.04 + _speed_ratio * 0.06
	draw_circle(pos, 36.0, Color(1.0, 1.0, 1.0, white_alpha))
	draw_circle(pos, 52.0, Color(1.0, 1.0, 1.0, white_alpha * 0.5))

	# >0.5c：蓝光晕渐显
	if _speed_ratio > 0.5:
		var blue_intensity: float = clampf((_speed_ratio - 0.5) / 0.45, 0.0, 1.0)
		blue_intensity *= (1.0 - _redline_ratio * 0.6)  # 红线临界时蓝晕稍退
		draw_circle(pos, 44.0, Color(Palette.C_BLUE.r, Palette.C_BLUE.g, Palette.C_BLUE.b, 0.12 * blue_intensity))
		draw_circle(pos, 64.0, Color(Palette.C_BLUE.r, Palette.C_BLUE.g, Palette.C_BLUE.b, 0.06 * blue_intensity))

	# 临近红线：红色脉冲光晕
	if _redline_ratio > 0.3:
		var pulse: float = 0.5 + 0.5 * sin(_t * 12.0)
		var red_alpha: float = _redline_ratio * 0.22 * pulse
		draw_circle(pos, 48.0, Color(Palette.C_RED.r, Palette.C_RED.g, Palette.C_RED.b, red_alpha))
		draw_circle(pos, 70.0, Color(Palette.C_RED.r, Palette.C_RED.g, Palette.C_RED.b, red_alpha * 0.4))

	# E 观测青闪
	if _flash_cyan > 0.01:
		draw_circle(pos, 42.0, Color(Palette.C_CYAN.r, Palette.C_CYAN.g, Palette.C_CYAN.b, 0.35 * _flash_cyan))
		draw_circle(pos, 66.0, Color(Palette.C_CYAN.r, Palette.C_CYAN.g, Palette.C_CYAN.b, 0.15 * _flash_cyan))

	# F 抓取橙闪
	if _flash_orange > 0.01:
		draw_circle(pos, 42.0, Color(1.0, 0.65, 0.2, 0.35 * _flash_orange))
		draw_circle(pos, 66.0, Color(1.0, 0.65, 0.2, 0.15 * _flash_orange))
