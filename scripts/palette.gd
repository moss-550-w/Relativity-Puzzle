class_name Palette
## 全局调色板 — 美术配色的唯一真源（静态类，仿 SpeedTimeCoupling）
## 通用 UI 色、四世界色卡、四分类色、统一星空绘制接口
## 用法：Palette.C_CYAN / Palette.world_accent(GameState.current_world) / Palette.draw_starfield(self, stars)


# ============================================================
# 通用 UI 色
# ============================================================

const C_CYAN: Color = Color(0.2, 0.9, 1.0)
const C_RED: Color = Color(1.0, 0.25, 0.2)
const C_GOLD: Color = Color(1.0, 0.85, 0.3)
const C_BLUE: Color = Color(0.35, 0.55, 1.0)
const C_DIM: Color = Color(0.4, 0.5, 0.7)
const C_PANEL_BG: Color = Color(0.03, 0.07, 0.12, 0.8)
const C_PANEL_EDGE: Color = Color(0.2, 0.8, 1.0, 0.5)

# 星点统一基色
const STAR_COLOR: Color = Color(0.5, 0.7, 1.0)


# ============================================================
# 四分类色（图鉴 / UI 分类，沿用 main_menu.CATEGORIES）
# ============================================================

const CATEGORY_COLORS: Array[Color] = [
	Color(0.3, 0.8, 1.0),   # 0 狭义相对论 — 青
	Color(0.6, 0.4, 1.0),   # 1 广义相对论 — 紫
	Color(0.3, 1.0, 0.6),   # 2 量子引力   — 绿
	Color(1.0, 0.7, 0.3),   # 3 熵宇宙学   — 橙
]


## 按分类索引取色（越界回退青）
static func category_color(idx: int) -> Color:
	if idx < 0 or idx >= CATEGORY_COLORS.size():
		return C_CYAN
	return CATEGORY_COLORS[idx]


# ============================================================
# 四世界色卡（world 取 GameState.World 枚举值 1..4）
# 每个世界：bg_top / bg_bottom / accent / grid
# ============================================================

const WORLD_PALETTE: Dictionary = {
	1: {  # 洛伦兹平原 — 狭义 · 平直时空（青）
		"bg_top": Color(0.04, 0.09, 0.13),
		"bg_bottom": Color(0.02, 0.05, 0.09),
		"accent": Color(0.30, 0.85, 1.0),
		"grid": Color(0.30, 0.85, 1.0, 0.10),
	},
	2: {  # 引力深渊 — 广义 · 弯曲时空（紫）
		"bg_top": Color(0.10, 0.05, 0.16),
		"bg_bottom": Color(0.05, 0.03, 0.10),
		"accent": Color(0.60, 0.40, 1.0),
		"grid": Color(0.60, 0.40, 1.0, 0.11),
	},
	3: {  # 量子泡沫秘境 — 量子（冰蓝）
		"bg_top": Color(0.05, 0.09, 0.16),
		"bg_bottom": Color(0.04, 0.06, 0.12),
		"accent": Color(0.40, 0.80, 1.0),
		"grid": Color(0.45, 0.70, 1.0, 0.10),
	},
	4: {  # 熵之终焉 — 热力学（暖橙）
		"bg_top": Color(0.14, 0.10, 0.06),
		"bg_bottom": Color(0.06, 0.05, 0.10),
		"accent": Color(1.0, 0.70, 0.30),
		"grid": Color(1.0, 0.65, 0.30, 0.10),
	},
}


static func _world_data(world: int) -> Dictionary:
	return WORLD_PALETTE.get(world, WORLD_PALETTE[1])


static func world_bg_top(world: int) -> Color:
	return _world_data(world)["bg_top"]


static func world_bg_bottom(world: int) -> Color:
	return _world_data(world)["bg_bottom"]


## 世界强调色（HUD 描边 / 网格 / 粒子高亮）
static func world_accent(world: int) -> Color:
	return _world_data(world)["accent"]


static func world_grid(world: int) -> Color:
	return _world_data(world)["grid"]


# ============================================================
# 统一星空接口
# ============================================================

## 生成星点数据 [{pos:Vector2, a:float}]；调用方持有后交给 draw_starfield 渲染
static func make_stars(count: int, w: float, h: float) -> Array:
	var stars: Array = []
	for i in count:
		stars.append({
			"pos": Vector2(randf_range(0.0, w), randf_range(0.0, h)),
			"a": randf_range(0.08, 0.3),
		})
	return stars


## 在任意 CanvasItem 的 _draw 中绘制星点
static func draw_starfield(ci: CanvasItem, stars: Array) -> void:
	for s in stars:
		ci.draw_rect(Rect2(s["pos"], Vector2(1.5, 1.5)), Color(STAR_COLOR.r, STAR_COLOR.g, STAR_COLOR.b, s["a"]), true)
