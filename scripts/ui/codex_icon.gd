class_name CodexIcon
extends Control
## 图鉴词条极简图标 — 24px 几何图标，程序化 _draw()
## 由 main_menu._make_entry_card() 实例化，传入 entry_id + unlocked 状态
## 分类分色（art.md §4.2）：狭义青 / 广义紫 / 量子绿 / 熵橙


const SIZE: float = 24.0
const LINE_W: float = 2.0

# 图标类型映射（词条 → 几何原型）
const ICON_MAP: Dictionary = {
	# 狭义相对论
	"time_dilation": "clock",
	"light_speed_barrier": "barrier",
	"light_clock": "clock",
	"light_cone": "cone",
	"twin_paradox": "person",
	# 广义相对论
	"gravitational_time_dilation": "clock",
	"wormhole": "portal",
	"traversable_wormhole": "portal",
	"ctc": "portal",
	"grandfather_paradox": "paradox",
	"kerr_black_hole": "black_hole",
	"ergosphere": "black_hole",
	"ring_singularity": "black_hole",
	# 量子引力
	"casimir_effect": "dots",
	"quantum_vacuum": "dots",
	"chronology_protection": "dots",
	# 熵宇宙学
	"entropy_arrow": "arrow",
	"block_universe": "cube",
	"wheeler_dewitt": "equation",
	"time_illusion": "eye",
	"maxwell_demon": "gate",
	"landauer_principle": "bit",
	"physicists_cabin": "person",
}

var _entry_id: String = ""
var _unlocked: bool = false
var _color: Color = Color.WHITE


func setup(entry_id: String, unlocked: bool, col: Color) -> void:
	_entry_id = entry_id
	_unlocked = unlocked
	_color = col
	queue_redraw()


func _draw() -> void:
	var alpha: float = 0.85 if _unlocked else 0.25
	var col: Color = Color(_color.r, _color.g, _color.b, alpha)
	var c: Vector2 = Vector2(SIZE / 2.0, SIZE / 2.0)

	var icon_type: String = ICON_MAP.get(_entry_id, "default")
	match icon_type:
		"clock":
			_draw_clock(c, col)
		"barrier":
			_draw_barrier(c, col)
		"cone":
			_draw_cone(c, col)
		"person":
			_draw_person(c, col)
		"portal":
			_draw_portal(c, col)
		"paradox":
			_draw_paradox(c, col)
		"black_hole":
			_draw_black_hole(c, col)
		"dots":
			_draw_dots(c, col)
		"arrow":
			_draw_arrow(c, col)
		"cube":
			_draw_cube(c, col)
		"equation":
			_draw_equation(c, col)
		"eye":
			_draw_eye(c, col)
		"gate":
			_draw_gate(c, col)
		"bit":
			_draw_bit(c, col)
		_:
			_draw_default(c, col)


# ============================================================
# 几何原型
# ============================================================

func _draw_clock(c: Vector2, col: Color) -> void:
	draw_arc(c, 9.0, 0, TAU, 32, col, LINE_W)
	draw_line(c, c + Vector2(0, -5), col, LINE_W, true)    # 分针
	draw_line(c, c + Vector2(3, 2), col, LINE_W * 0.7, true) # 时针


func _draw_barrier(c: Vector2, col: Color) -> void:
	draw_line(c + Vector2(-8, -7), c + Vector2(-8, 7), col, LINE_W, true)
	draw_line(c + Vector2(0, -3), c + Vector2(0, 7), col, LINE_W, true)
	draw_line(c + Vector2(6, 0), c + Vector2(10, 2), col, LINE_W, true)  # 速度箭头
	draw_line(c + Vector2(8, 0), c + Vector2(6, 2), col, LINE_W, true)


func _draw_cone(c: Vector2, col: Color) -> void:
	draw_line(c + Vector2(-8, 8), c, col, LINE_W, true)
	draw_line(c + Vector2(8, 8), c, col, LINE_W, true)
	draw_line(c + Vector2(-3, 8), c + Vector2(3, 8), col, LINE_W * 0.5, true)  # 时间轴
	draw_arc(c, 3.0, PI / 4.0, 3.0 * PI / 4.0, 12, col, LINE_W * 0.6)


func _draw_person(c: Vector2, col: Color) -> void:
	draw_circle(c + Vector2(0, -6), 3.5, col)            # 头
	draw_line(c + Vector2(0, -2), c + Vector2(0, 6), col, LINE_W, true)  # 身体
	draw_line(c + Vector2(0, 0), c + Vector2(-5, 4), col, LINE_W, true)  # 左臂
	draw_line(c + Vector2(0, 0), c + Vector2(5, 4), col, LINE_W, true)   # 右臂
	draw_line(c + Vector2(0, 6), c + Vector2(-4, 10), col, LINE_W, true) # 左腿
	draw_line(c + Vector2(0, 6), c + Vector2(4, 10), col, LINE_W, true)  # 右腿


func _draw_portal(c: Vector2, col: Color) -> void:
	draw_arc(c + Vector2(-3.5, 0), 5.5, 0, TAU, 24, col, LINE_W)
	draw_arc(c + Vector2(3.5, 0), 5.5, 0, TAU, 24, col, LINE_W)
	# 连接线
	var tw: float = LINE_W * 0.7
	draw_line(c + Vector2(-3.5, -5.5), c + Vector2(3.5, -5.5), col, tw, true)
	draw_line(c + Vector2(-3.5, 5.5), c + Vector2(3.5, 5.5), col, tw, true)


func _draw_paradox(c: Vector2, col: Color) -> void:
	draw_arc(c, 7.0, 0, TAU, 32, col, LINE_W)
	draw_arc(c, 4.5, PI, TAU, 16, col, LINE_W * 0.8)  # ∞ 中间交叉
	draw_arc(c + Vector2(0, -6), 4.5, 0, PI, 16, col, LINE_W * 0.8)


func _draw_black_hole(c: Vector2, col: Color) -> void:
	draw_circle(c, 8.0, Color(col.r, col.g, col.b, 0.2))  # 阴影
	draw_circle(c, 3.0, Color(0, 0, 0, 1))                 # 黑影
	draw_arc(c, 7.0, 0, TAU, 32, col, LINE_W)              # 事件视界
	draw_arc(c, 9.5, PI / 3.0, 2.3 * PI / 3.0, 16, col, LINE_W * 0.5)  # 吸积环


func _draw_dots(c: Vector2, col: Color) -> void:
	var r: float = LINE_W * 1.1
	draw_circle(c + Vector2(-5, -4), r, col)
	draw_circle(c + Vector2(3, -5), r * 0.8, col)
	draw_circle(c + Vector2(-2, 3), r * 0.7, col)
	draw_circle(c + Vector2(5, 2), r * 0.9, col)
	draw_circle(c + Vector2(-1, -1), r, col)
	# 虚线连接
	draw_line(c + Vector2(-5, -4), c + Vector2(3, -5), col, LINE_W * 0.3, true)
	draw_line(c + Vector2(-1, -1), c + Vector2(5, 2), col, LINE_W * 0.3, true)


func _draw_arrow(c: Vector2, col: Color) -> void:
	# 左→右 增长箭头
	draw_line(c + Vector2(-8, 0), c + Vector2(5, 0), col, LINE_W, true)
	draw_line(c + Vector2(5, 0), c + Vector2(-1, -4), col, LINE_W, true)   # 箭头
	draw_line(c + Vector2(5, 0), c + Vector2(-1, 4), col, LINE_W, true)
	# 副微线
	var sc: float = 0.4
	draw_line(c + Vector2(-8, -8), c + Vector2(-4, -8), Color(col.r, col.g, col.b, sc), LINE_W * 0.6, true)
	draw_line(c + Vector2(2, 7), c + Vector2(8, 7), Color(col.r, col.g, col.b, sc * 1.5), LINE_W * 0.8, true)


func _draw_cube(c: Vector2, col: Color) -> void:
	# 正面
	draw_rect(Rect2(c + Vector2(-6, -4), Vector2(7, 7)), col, false, LINE_W * 0.8)
	# 顶面
	draw_line(c + Vector2(-2, -7), c + Vector2(-6, -4), col, LINE_W * 0.7, true)
	draw_line(c + Vector2(-2, -7), c + Vector2(3, -7), col, LINE_W * 0.7, true)
	draw_line(c + Vector2(3, -7), c + Vector2(1, -4), col, LINE_W * 0.7, true)


func _draw_equation(c: Vector2, col: Color) -> void:
	var font := ThemeDB.fallback_font
	draw_string(font, c + Vector2(-6, 5), "Ĥ", 0, -1, 11, col)
	draw_string(font, c + Vector2(1, 8), "=0", 0, -1, 9, col)


func _draw_eye(c: Vector2, col: Color) -> void:
	draw_arc(c + Vector2(0, 1), 7.0, PI / 5.0, 4.0 * PI / 5.0, 16, col, LINE_W)  # 眼睑
	draw_arc(c + Vector2(0, 1), 7.0, -(PI / 5.0), -(4.0 * PI / 5.0), 16, col, LINE_W)
	draw_circle(c + Vector2(0, 1), 3.0, Color(col.r, col.g, col.b, 0.4))  # 瞳孔


func _draw_gate(c: Vector2, col: Color) -> void:
	# 隔墙 + 闸门
	draw_line(c + Vector2(0, -7), c + Vector2(0, -2), col, LINE_W, true)   # 上半墙
	draw_line(c + Vector2(0, 3), c + Vector2(0, 8), col, LINE_W, true)     # 下半墙
	draw_line(c + Vector2(-3, -2), c + Vector2(3, -2), col, LINE_W * 0.7, true)  # 门楣
	draw_line(c + Vector2(-3, 3), c + Vector2(3, 3), col, LINE_W * 0.7, true)    # 门槛


func _draw_bit(c: Vector2, col: Color) -> void:
	# 0/1 比特
	var font := ThemeDB.fallback_font
	draw_string(font, c + Vector2(-7, 5), "0", 0, -1, 10, Color(col.r, col.g, col.b, 0.5))
	draw_string(font, c + Vector2(1, 5), "1", 0, -1, 10, col)
	draw_line(c + Vector2(-2, -2), c + Vector2(4, -4), col, LINE_W * 0.6, true)  # →


func _draw_default(c: Vector2, col: Color) -> void:
	draw_arc(c, 7.0, 0, TAU, 24, col, LINE_W)
	draw_line(c + Vector2(-3, -3), c + Vector2(3, 3), col, LINE_W * 0.5, true)
