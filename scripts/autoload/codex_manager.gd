extends Node
## CodexManager — 图鉴解锁管理
## 存储已解锁词条，发射解锁信号供 HUD toast 显示


# ---- 词条数据 ----


const WORLD_1_ENTRIES: Dictionary = {
	"time_dilation": {
		"name": "时间膨胀",
		"desc": "运动越快，时间越慢。你的每一秒，世界已历 γ 秒。",
		"category": "special_relativity"
	},
	"light_speed_barrier": {
		"name": "光速不变与光速壁垒",
		"desc": "光速是宇宙的速度上限。接近它时，能量需求趋近无穷。",
		"category": "special_relativity"
	},
	"light_cone": {
		"name": "光锥与因果结构",
		"desc": "你的未来只能抵达光锥之内。锥外的时空对你毫无意义。",
		"category": "special_relativity"
	},
	"twin_paradox": {
		"name": "双生子佯谬",
		"desc": "高速旅行的双胞胎返回后比留在地球的更年轻——时间对每个人并不公平。",
		"category": "special_relativity"
	},
	"gravitational_time_dilation": {
		"name": "引力时间膨胀",
		"desc": "强引力场中时间流速比远处慢。越靠近大质量天体，时钟走得越慢。",
		"category": "general_relativity"
	},
	"wormhole": {
		"name": "虫洞与爱因斯坦-罗森桥",
		"desc": "时空两点之间的理论捷径。虫洞是广义相对论的数学解，但可穿越虫洞需要负能量——尚未被实验证实。",
		"category": "general_relativity"
	},
	"ctc": {
		"name": "闭合类时曲线（CTC）",
		"desc": "时空中回到自身过去的闭合路径。CTC 在理论中存在，但其物理可实现性未知——也许宇宙禁止时间旅行。",
		"category": "general_relativity"
	},
	"grandfather_paradox": {
		"name": "祖父悖论",
		"desc": "若回到过去阻止自己出生，你如何存在？因果闭环的自洽性危机——宇宙或许不容许这样的矛盾。",
		"category": "general_relativity"
	},
	"kerr_black_hole": {
		"name": "克尔黑洞",
		"desc": "旋转黑洞——中心不是奇点，而是环状奇环。能层中时空本身被拖拽旋转。克尔度规(1963)是爱因斯坦场方程的精确解。",
		"category": "general_relativity"
	},
	"ring_singularity": {
		"name": "奇环与裸奇点",
		"desc": "克尔黑洞的奇点是环状的——理论上有两个视界。若内视界消失，奇环将裸露在外——宇宙是否允许裸奇点存在？",
		"category": "general_relativity"
	},
}

# ---- 状态 ----

## 已解锁词条集合
var unlocked: Dictionary = {}

# ---- 信号 ----

## 词条解锁事件（传递 entry_id 与 entry_data）
signal entry_unlocked(entry_id: String, entry_data: Dictionary)


# ---- 方法 ----

## 解锁指定词条（已解锁则无操作）
func unlock(entry_id: String) -> void:
	if unlocked.has(entry_id):
		return
	# 从内置数据查找
	var data: Dictionary = {}
	if WORLD_1_ENTRIES.has(entry_id):
		data = WORLD_1_ENTRIES[entry_id]
	else:
		push_warning("CodexManager: 未知词条 '%s'" % entry_id)
		data = {"name": entry_id, "desc": "", "category": "unknown"}
	unlocked[entry_id] = data
	entry_unlocked.emit(entry_id, data)


## 某词条是否已解锁
func is_unlocked(entry_id: String) -> bool:
	return unlocked.has(entry_id)


## 获取已解锁词条总数
func get_unlocked_count() -> int:
	return unlocked.size()


## 重置（谜题重置时不丢图鉴；仅完全新游戏时调用）
func reset_all() -> void:
	unlocked.clear()
