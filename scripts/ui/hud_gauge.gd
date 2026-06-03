extends Control
## 科幻环形仪表 — 显示速度占光速比例 (0 → c)
## 自定义绘制：背景轨道 + 辉光填充弧 + 刻度 + 红线警示段


var ratio: float = 0.0          # 填充比例 [0,1]（speed / c）
var glow_color: Color = Color(0.2, 0.9, 1.0)
var redline_ratio: float = 0.99 # 红线位置（占满比例）

const START_ANGLE := 0.75 * PI  # 起始角（左下）
const END_ANGLE := 2.25 * PI    # 结束角（右下），共 270°
const ARC_WIDTH := 7.0


func set_values(r: float, glow: Color) -> void:
	ratio = clampf(r, 0.0, 1.0)
	glow_color = glow
	queue_redraw()


func _draw() -> void:
	var center := size / 2.0
	var radius := minf(size.x, size.y) / 2.0 - 8.0
	var span := END_ANGLE - START_ANGLE

	# --- 背景轨道 ---
	draw_arc(center, radius, START_ANGLE, END_ANGLE, 96, Color(0.08, 0.16, 0.24, 0.7), ARC_WIDTH, true)

	# --- 红线警示段（末端 1% 标红底）---
	var rl_start := START_ANGLE + span * redline_ratio
	draw_arc(center, radius, rl_start, END_ANGLE, 12, Color(0.8, 0.1, 0.1, 0.5), ARC_WIDTH, true)

	# --- 填充弧（双层模拟辉光）---
	if ratio > 0.001:
		var fill_end := START_ANGLE + span * ratio
		draw_arc(center, radius, START_ANGLE, fill_end, 96, Color(glow_color.r, glow_color.g, glow_color.b, 0.22), ARC_WIDTH * 2.4, true)
		draw_arc(center, radius, START_ANGLE, fill_end, 96, glow_color, ARC_WIDTH, true)
		# 端点亮点
		var tip := center + Vector2(cos(fill_end), sin(fill_end)) * radius
		draw_circle(tip, 5.0, Color(1, 1, 1, 0.9))
		draw_circle(tip, 9.0, Color(glow_color.r, glow_color.g, glow_color.b, 0.4))

	# --- 刻度 ---
	var ticks := 10
	for i in ticks + 1:
		var a := START_ANGLE + span * (float(i) / ticks)
		var outer := center + Vector2(cos(a), sin(a)) * radius
		var inner := center + Vector2(cos(a), sin(a)) * (radius - 9.0)
		var major := (i % 5 == 0)
		var col := Color(0.4, 0.8, 1.0, 0.6) if major else Color(0.3, 0.55, 0.7, 0.4)
		draw_line(inner, outer, col, 2.0 if major else 1.0)
