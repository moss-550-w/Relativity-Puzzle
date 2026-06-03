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
	"ergosphere": {
		"name": "能层与帧拖拽",
		"desc": "旋转黑洞外部存在能层——时空本身被拖拽着旋转。在能层内，静止不再是静止：你必须随黑洞一起转动。",
		"category": "general_relativity"
	},
	"ring_singularity": {
		"name": "奇环与裸奇点",
		"desc": "克尔黑洞的奇点是环状的——理论上有两个视界。若内视界消失，奇环将裸露在外——宇宙是否允许裸奇点存在？",
		"category": "general_relativity"
	},
	"casimir_effect": {
		"name": "卡西米尔效应与负能量",
		"desc": "真空中两块极近金属板间产生吸引力——真空不空。板间能量密度低于真空零点，形成负能量区域。",
		"category": "quantum_gravity"
	},
	"quantum_vacuum": {
		"name": "量子真空涨落",
		"desc": "真空中虚粒子对不断创生湮灭——看似空无一物之处，实则是沸腾的量子泡沫。裂隙即是涨落的宏观显现。",
		"category": "quantum_gravity"
	},
	"chronology_protection": {
		"name": "时序保护猜想",
		"desc": "霍金(1992)提出：物理定律禁止宏观时间旅行。量子真空涨落在CTC形成时会发散——大自然讨厌时间机器。",
		"category": "quantum_gravity"
	},
	"entropy_arrow": {
		"name": "熵增定律与时间箭头",
		"desc": "孤立系统熵永不减少——熵增给定了时间的方向。你在局部可以暂缓崩解，但宇宙总熵仍在攀升。",
		"category": "entropy_cosmology"
	},
	"block_universe": {
		"name": "块状宇宙",
		"desc": "过去、现在、未来同样真实存在——时间是四维时空的一个维度，而非流动的河流。不同时区只是不同的切片。",
		"category": "entropy_cosmology"
	},
	"wheeler_dewitt": {
		"name": "惠勒-德维特方程",
		"desc": "Ĥ|Ψ⟩ = 0。在量子引力层面，时间变量从方程中消失。时间可能不是宇宙的基本要素——它是宏观涌现的。",
		"category": "entropy_cosmology"
	},
	"time_illusion": {
		"name": "时间的主观性错觉",
		"desc": "如果时间不是基本量，那么'流动'的感觉从何而来？也许时间只是意识为理解块状宇宙而创造的故事。",
		"category": "entropy_cosmology"
	},
	"light_clock": {
		"name": "光钟与时间膨胀",
		"desc": "爱因斯坦的光钟思想实验：运动中的光钟——光子走斜边——比静止的走得慢。时间膨胀不是钟的误差，是时空本身的几何。",
		"category": "special_relativity"
	},
	"traversable_wormhole": {
		"name": "可穿越虫洞",
		"desc": "虫洞是时空的捷径，但维持其开启需要负能量——卡西米尔效应是已知唯一能产生负能量的物理机制。没有负能量，虫洞在形成瞬间就会坍缩。",
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
