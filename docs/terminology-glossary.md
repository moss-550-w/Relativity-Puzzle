# 《时空错位：相对论漫游》术语表

**用途**：统一项目中所有物理概念、游戏机制、代码命名的术语定义。开发团队、AI 辅助、图鉴文案均以此表为准。

---

## 一、物理学核心术语

### 狭义相对论（Special Relativity）

| 术语 | 英文 | 通俗解释 | 游戏机制映射 |
|------|------|----------|--------------|
| **时间膨胀** | Time Dilation | 运动越快，时间越慢。你的每一秒，世界已历 γ 秒。 | World 1 核心：`scene_time_scale = γ` |
| **洛伦兹因子** | Lorentz Factor (γ) | γ = 1 / √(1 − v²/c²)，时间膨胀的倍数。v=0 时 γ=1；v→c 时 γ→∞。 | `speed_time_coupling.gd` 中 `lorentz_factor()` |
| **光速不变** | Invariance of Light Speed | 任何参考系中真空光速恒定，299,792,458 m/s。 | 游戏内 c = 1000.0 px/s |
| **光速壁垒** | Light Speed Barrier | 有质量物体永远无法达到光速。接近时能量需求趋近无穷。 | M1-2 红线壁垒 `redline_barrier.gd` |
| **光速红线** | Redline | v = 0.99c 的硬边界，触及时强制弹回。 | `SPEED_REDLINE = 990.0` |
| **尺缩效应** | Length Contraction | 运动方向上的长度收缩为静止长度的 1/γ。 | Player 视觉横向压缩 |
| **光锥** | Light Cone | 时空中某事件能因果影响/被影响的所有区域。锥内=可达，锥外=无因果关联。 | M1-3 `light_cone_boundary.gd` |
| **未来光锥** | Future Light Cone | 从此事件出发，以光速可能到达的所有时空点。 | M1-3 地面虚线区域 |
| **蓝移** | Blueshift | 相对靠近时，光频率升高，颜色偏蓝。 | `time_warp.gdshader`，factor > 1 |
| **红移** | Redshift | 相对远离时，光频率降低，颜色偏红。 | `time_warp.gdshader`，factor < 1 |
| **双生子佯谬** | Twin Paradox | 高速旅行的双胞胎返回后发现比留在地球的更年轻。 | 世界 1 隐藏彩蛋 NPC |
| **相对论性质量** | Relativistic Mass | 速度增加时等效质量增大，需更多能量继续加速。 | 速度累积加速度曲线 |

### 广义相对论（General Relativity）

| 术语 | 英文 | 通俗解释 | 游戏机制映射 |
|------|------|----------|--------------|
| **引力时间膨胀** | Gravitational Time Dilation | 强引力场中，时间流速比远处慢。越靠近质量，时间越慢。 | World 2 核心 A |
| **事件视界** | Event Horizon | 黑洞表面边界，内部任何事物（包括光）都无法逃逸。 | 黑洞边缘 `time_scale = 0` |
| **史瓦西半径** | Schwarzschild Radius | rₛ = 2GM/c²，事件视界的半径。 | 计算引力时间膨胀的边界值 |
| **引力透镜** | Gravitational Lensing | 大质量天体弯曲经过其附近的光线。 | `gravitational_lens.gdshader` |
| **虫洞** | Wormhole / Einstein-Rosen Bridge | 连接时空两点的理论通道。 | World 2 双向虫洞系统 |
| **爱因斯坦-罗森桥** | Einstein-Rosen Bridge | 虫洞的物理学术名。 | 图鉴词条 `wormhole` |
| **闭合类时曲线** | CTC (Closed Timelike Curve) | 时空中回到自身过去的闭合路径。理论允许，工程不可能。 | World 2 CTC 回溯机制 |
| **祖父悖论** | Grandfather Paradox | 回到过去杀死自己的祖父 → 自己如何存在？逻辑自洽性矛盾。 | 接触"过去的自己"触发悖论重置 |
| **自洽性原则** | Novikov Self-Consistency | 任何时间旅行行为必须与已发生的历史自洽。 | CTC 谜题设计基础 |
| **克尔黑洞** | Kerr Black Hole | 旋转黑洞，具有奇环而非奇点。 | World 2 BOSS 关 |
| **时空弯曲** | Spacetime Curvature | 质量使时空几何弯曲，物体在弯曲时空中沿测地线运动。 | 跳跃轨迹弯曲视觉 |

### 量子引力与时空本质

| 术语 | 英文 | 通俗解释 | 游戏机制映射 |
|------|------|----------|--------------|
| **卡西米尔效应** | Casimir Effect | 真空中两块极近金属板间产生吸引力。证明真空不空。 | World 3 负能量板 |
| **负能量** | Negative Energy | 低于真空零点能的能量密度。理论可用于稳定虫洞。 | 负能量球，注入虫洞 |
| **量子真空涨落** | Quantum Vacuum Fluctuation | 真空中粒子-反粒子对不断创生与湮灭。 | 量子裂隙的粒子预兆 |
| **普朗克尺度** | Planck Scale | 约 1.6×10⁻³⁵ m，时空可能不再连续的最小尺度。 | 量子泡沫裂隙 2–3 秒窗口 |
| **时空泡沫** | Spacetime Foam | 普朗克尺度下时空剧烈涨落的假设图像。 | World 3 视觉主题 |
| **时序保护猜想** | Chronology Protection Conjecture | 霍金提出：物理定律阻止宏观时间旅行。 | 连续回溯 ≥ 3 次触发粒子风暴 |
| **观测者效应** | Observer Effect | 量子系统中，观测行为影响被观测对象。 | E 键"观测"延长裂隙 |
| **叠加态** | Superposition | 量子系统在被观测前同时处于多个可能状态。 | 裂隙网络随机刷新 |

### 熵与时间箭头

| 术语 | 英文 | 通俗解释 | 游戏机制映射 |
|------|------|----------|--------------|
| **热力学第二定律** | Second Law of Thermodynamics | 孤立系统的熵永不减少，总是趋向最大。 | World 4 全局熵增 |
| **熵** | Entropy | 系统无序度的度量。时间箭头指向熵增方向。 | `entropy_system.gd` |
| **时间箭头** | Arrow of Time | 时间单向流动的原因：熵增给出热力学箭头。 | World 4 核心主题 |
| **局部秩序** | Local Order | 可以用能量在局部区域减少熵，但总熵仍增加。 | 秩序能量干预 |
| **块状宇宙** | Block Universe | 过去、现在、未来同样真实存在，时间是四维时空的一个维度。 | World 4 底层：所有时间切片并排可视 |
| **惠勒-德维特方程** | Wheeler-DeWitt Equation | 量子引力中"时间"变量从方程中消失，暗示时间可能不是基本量。 | 图鉴词条 `wheeler_dewitt` |
| **时间的主观性** | Subjectivity of Time | 时间可能是宏观涌现现象，而非宇宙基本结构。 | World 4 底层叙事 |

---

## 二、游戏设计术语

### 通用设计

| 术语 | 定义 |
|------|------|
| **时空观测员** | 玩家角色。抽象几何体 + 斗篷剪影。 |
| **时空碎片** | 终点收集物。金色菱形，修复一块时空结构 = 完成关卡。 |
| **图鉴** (Codex) | 游戏中解锁的物理学知识条目系统。4 大分类，主线 + 隐藏词条。 |
| **软锁定** (Soft Lock) | 玩家能继续操作但无法通关的状态。本项目设计中必须杜绝。 |
| **预兆** (Telegraph) | 危险/事件发生前的视觉/音频提示，确保玩家有时间反应。 |

### 游戏机制

| 术语 | 代码标识 | 定义 |
|------|----------|------|
| **场景时间倍率** | `scene_time_scale` | 场景物体的时间流速倍数。世界 1 由玩家速度驱动，= γ。 |
| **缩放 delta** | `scaled_delta(delta)` | 原始 delta × scene_time_scale，供场景物体使用。 |
| **玩家 delta** | `player_delta(delta)` | 即原始 delta，保证玩家操作实时。 |
| **速度累积** | `ramped_speed` | 长按方向键持续增长的内部目标速度。 |
| **红线弹回** | Redline Bounce | 速度达 0.99c 时强制弹回 + 特效 + 清除累积。 |
| **场景快照** | `SceneSnapshot` | 虫洞 CTC 回溯时重建过去场景状态的预录数据。 |
| **秩序能量** | Order Energy | World 4 中用于局部熵减干预的有限资源。 |
| **观测延长** | Observe Extend | E 键能力：延长量子裂隙存续 2s（冷却中）。 |
| **负能量球** | Negative Energy Orb | 从负能量板区收集，携带时限内可注入虫洞稳定之。 |

### 输入动作

| 动作名 | 绑定 | 用途 |
|--------|------|------|
| `move_left` | A / ← | 向左移动、长按加速累积 |
| `move_right` | D / → | 向右移动、长按加速累积 |
| `jump` | W / 空格 | 跳跃（世界 2 起追加二段跳） |
| `sprint` | LShift | 速度累积速率 ×3.5 |
| `observe` | E | 世界 3：延长量子裂隙 |
| `grab` | F | 世界 2：搬运虫洞口/负能量板 |
| `reset_puzzle` | R | 即时重置当前谜题 |

### 信号命名

| 信号 | 发射者 | 含义 |
|------|--------|------|
| `scene_time_scale_changed(new_scale)` | TimeManager | 场景时间倍率变化 |
| `puzzle_reset` | GameState | 谜题重置触发 |
| `level_completed(level_name)` | GameState | 关卡完成 |
| `entry_unlocked(entry_id, data)` | CodexManager | 图鉴词条解锁 |
| `redline_bounced()` | Player | 玩家撞上红线弹回 |

### 物理层

| 层 ID | 名称 | 碰撞关系 |
|-------|------|----------|
| 1 | world | 地面、墙壁、障碍物。与 player 碰撞。 |
| 2 | player | 玩家角色。与 world、platform 碰撞。 |
| 3 | platform | 移动平台（单向通过）。 |
| 4 | gate | 周期闸门阻挡。 |

---

## 三、代码命名速查

### 类名

| 类 | 文件 | 类型 |
|----|------|------|
| `GameState` | `scripts/autoload/game_state.gd` | Autoload 单例 |
| `TimeManager` | `scripts/autoload/time_manager.gd` | Autoload 单例 |
| `CodexManager` | `scripts/autoload/codex_manager.gd` | Autoload 单例 |
| `AudioManager` | `scripts/autoload/audio_manager.gd` | Autoload 单例 |
| `PlayerMetrics` | `scripts/autoload/player_metrics.gd` | Autoload 单例 |
| `SpeedTimeCoupling` | `scripts/mechanics/speed_time_coupling.gd` | 静态工具类 |
| `TimeAffectedBody` | `scripts/mechanics/time_dilation.gd` | 基类 |
| `PlayerAbilities` | `scripts/player/player_abilities.gd` | 组件 |
| `CodexEntry` | `scripts/ui/codex_entry.gd` | Resource |

### 常量

| 常量 | 值 | 位置 |
|------|-----|------|
| `LIGHT_SPEED` | 1000.0 | `speed_time_coupling.gd`, `time_manager.gd` |
| `SPEED_REDLINE` | 990.0 (0.99c) | `speed_time_coupling.gd` |
| `MIN_SCALE` | 1.0 | `time_manager.gd` |
| `MAX_SCALE` | 50.0 | `time_manager.gd` |
| `SAMPLE_RATE` | 44100 | `audio_manager.gd` |

### 导出变量命名示例

```gdscript
# ✅ 正确：分组 + 语义化命名
@export_category("Movement")
@export var base_speed: float = 150.0
@export var max_speed: float = 980.0

# ❌ 错误：无分组、缩写不明确
@export var ts: float = 1.0
@export var max_v: float = 500.0
```

---

## 四、结局术语

| 结局 ID | 名称 | 中文 | 触发逻辑 |
|---------|------|------|----------|
| `TOWARD_FUTURE` | Toward Future | 奔赴未来 | 积极修复碎片 + 使用近光速装置 |
| `CLOSED_LOOP_PRISON` | Closed Loop Prison | 闭环囚笼 | CTC 回溯 ≥ 3 次 |
| `SOURCE_INSIGHT` | Source Insight | 本源顿悟 | 底层静止 > 60s + 熵减干预 < 3 |

---

## 五、图鉴词条 ID 清单

### 狭义相对论（special_relativity）

| ID | 中文名 | 获取方式 |
|----|--------|----------|
| `time_dilation` | 时间膨胀 | M1-1 主线 |
| `light_speed_barrier` | 光速不变与光速壁垒 | M1-2 主线 |
| `light_cone` | 光锥与因果结构 | M1-3 主线 |
| `twin_paradox` | 双生子佯谬 | 隐藏彩蛋 |

### 广义相对论（general_relativity）

| ID | 中文名 | 获取方式 |
|----|--------|----------|
| `gravitational_time_dilation` | 引力时间膨胀 | M2-1 主线 |
| `wormhole` | 虫洞与爱因斯坦-罗森桥 | M2-2 主线 |
| `ctc` | 闭合类时曲线 | M2-2 主线 |
| `grandfather_paradox` | 祖父悖论 | 悖论触发 |

### 量子引力（quantum_gravity）

| ID | 中文名 | 获取方式 |
|----|--------|----------|
| `casimir_effect` | 卡西米尔效应与负能量 | M3-1 主线 |
| `quantum_vacuum` | 量子真空涨落 | M3-2 主线 |
| `planck_foam` | 普朗克尺度时空泡沫 | M3-3 主线 |
| `chronology_protection` | 时序保护猜想 | 时序保护触发 |

### 熵宇宙学（entropy_cosmology）

| ID | 中文名 | 获取方式 |
|----|--------|----------|
| `entropy_arrow` | 熵增定律与时间箭头 | W4 上层 |
| `block_universe` | 块状宇宙 | W4 中层 |
| `wheeler_dewitt` | 惠勒-德维特方程 | W4 底层 |
| `time_illusion` | 时间的主观性错觉 | W4 底层 |

---

## 六、物理学公式速查

### 洛伦兹因子
```
γ = 1 / √(1 − v²/c²)

v = 0     → γ = 1.0     （无时间膨胀）
v = 0.8c  → γ ≈ 1.67
v = 0.95c → γ ≈ 3.20
v = 0.99c → γ ≈ 7.09    （红线触发）
v → c     → γ → ∞
```

### 引力时间膨胀（近似）
```
t₀ = t_f × √(1 − rₛ/r)

rₛ = 2GM/c²  （史瓦西半径）
r  = 距引力源距离

r → rₛ  → t₀ → 0  （事件视界附近时间停滞）
r → ∞   → t₀ → t_f （远离引力源，时间正常）
```

### 尺缩效应
```
L = L₀ / γ

L₀ = 静止长度
L  = 运动观察者测得的长度
```

### 热力学第二定律
```
ΔS_universe ≥ 0

局部可减熵，但总宇宙熵永增。
```

---

## 七、缩写速查

| 缩写 | 全称 | 中文 |
|------|------|------|
| SR | Special Relativity | 狭义相对论 |
| GR | General Relativity | 广义相对论 |
| CTC | Closed Timelike Curve | 闭合类时曲线 |
| γ | Lorentz Factor | 洛伦兹因子 |
| c | Speed of Light | 光速 |
| rₛ | Schwarzschild Radius | 史瓦西半径 |
| QM | Quantum Mechanics | 量子力学 |
| QG | Quantum Gravity | 量子引力 |

---

> **重要提示**：术语表中的"游戏机制映射"列为开发时的硬约束。凡涉及物理概念的游戏功能，其行为必须与对应物理结论一致。彩蛋/假说性内容必须在图鉴中标注"此为理论假说，尚未实验证实"。
