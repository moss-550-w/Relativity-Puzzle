# AGENTS.md for 《时空错位：相对论漫游》

## 项目概述

《时空错位：相对论漫游》是一款2D横版解谜/轻平台跳跃独立游戏，使用Godot Engine 4.x开发。核心设计理念：**玩法=物理原理，谜题=知识点**。玩家扮演“时空观测员”，在块状宇宙碎片化时空中修复时空裂隙，通过四大关卡世界（狭义相对论→广义相对论→量子引力→熵与时间本质）逐步理解相对论核心概念。

---

## 技术栈

- **引擎**：Godot 4.4+（使用GDScript）
- **版本控制**：Git
- **美术资源**：手绘卡通/像素风2D（低分辨率，便于单人开发）
- **音频**：程序化音频生成（WAV合成）或简易音效库
- **目标平台**：Windows/macOS/Linux PC优先

---

## 项目架构

```
timewarp-game/
├── project.godot
├── README.md
├── AGENTS.md                          # 本文件
├── docs/
│   ├── design-doc.md                  # 完整设计文档
│   ├── physics-reference.md           # 物理学参考与准确性校验
│   └── terminology-glossary.md        # 术语表
├── assets/
│   ├── sprites/                       # 精灵图资源
│   │   ├── player/                    # 玩家角色动画帧
│   │   ├── environment/               # 场景物件精灵
│   │   ├── ui/                        # UI元素精灵
│   │   └── effects/                   # 特效精灵（时间扭曲/粒子等）
│   ├── audio/                         # 音效与音乐
│   ├── fonts/                         # 字体文件
│   └── shaders/                       # 自定义着色器
│       ├── time_warp.gdshader         # 时间效应画面扭曲
│       ├── gravitational_lens.gdshader # 引力透镜畸变
│       ├── redshift.gdshader          # 红移/蓝移色彩偏移
│       └── quantum_foam.gdshader      # 量子泡沫噪点效果
├── scenes/
│   ├── world_1_lorentz/              # 世界1：洛伦兹平原
│   │   ├── level_1_1.tscn
│   │   ├── level_1_2.tscn
│   │   └── level_1_3.tscn
│   ├── world_2_gravity/              # 世界2：引力深渊
│   │   ├── level_2_1.tscn
│   │   ├── level_2_2.tscn
│   │   └── boss_ker_blackhole.tscn
│   ├── world_3_quantum/              # 世界3：量子泡沫秘境
│   │   ├── level_3_1.tscn
│   │   ├── level_3_2.tscn
│   │   └── level_3_3.tscn
│   ├── world_4_entropy/              # 世界4：熵之终焉
│   │   ├── level_4_upper.tscn
│   │   ├── level_4_middle.tscn
│   │   └── level_4_bottom.tscn
│   ├── ui/                           # UI场景
│   │   ├── main_menu.tscn
│   │   ├── hud.tscn
│   │   ├── codex.tscn                # 时空图鉴
│   │   ├── pause_menu.tscn
│   │   └── ending_cutscenes/         # 三结局演出
│   └── minigames/                    # 趣味挑战小游戏
│       ├── light_clock.tscn
│       └── wormhole_engineer.tscn
├── scripts/
│   ├── autoload/                     # 全局单例
│   │   ├── game_state.gd             # 游戏状态管理
│   │   ├── time_manager.gd           # 全局时间控制系统
│   │   ├── codex_manager.gd          # 图鉴解锁管理
│   │   ├── audio_manager.gd          # 音频管理
│   │   └── player_metrics.gd         # 玩家行为追踪（结局判断）
│   ├── player/
│   │   ├── player.gd                 # 玩家基础移动与状态机
│   │   └── player_abilities.gd      # 特殊能力（观测/搬运）
│   ├── mechanics/                    # 核心物理机制
│   │   ├── time_dilation.gd          # 时间膨胀系统
│   │   ├── speed_time_coupling.gd    # 速度-时间耦合（世界1）
│   │   ├── gravity_time_dilation.gd  # 引力时间膨胀（世界2）
│   │   ├── wormhole.gd               # 双向虫洞系统
│   │   ├── ctc_handler.gd            # CTC闭环检测与悖论处理
│   │   ├── negative_energy.gd        # 负能量板机制（世界3）
│   │   ├── quantum_fissure.gd        # 量子泡沫裂隙（世界3）
│   │   ├── entropy_system.gd         # 全局熵增系统（世界4）
│   │   └── light_cone_boundary.gd    # 光锥边界检测
│   ├── objects/                      # 交互物件
│   │   ├── moving_platform.gd
│   │   ├── gravitational_body.gd     # 引力源天体
│   │   ├── wormhole_portal.gd        # 虫洞口
│   │   ├── negative_energy_plate.gd  # 负能量金属板
│   │   ├── quantum_fissure_spawner.gd # 量子裂隙生成器
│   │   └── entropy_platform.gd       # 受熵增影响的平台
│   ├── npc/                          # NPC脚本
│   │   ├── twin_paradox_npc.gd       # 双生子佯谬NPC
│   │   └── einstein_hawking_npc.gd   # 彩蛋物理学家NPC
│   └── ui/                           # UI脚本
│       ├── codex_entry.gd            # 图鉴词条组件
│       ├── relative_clock.gd         # 相对时钟HUD
│       └── ending_trigger.gd         # 结局触发判定
└── resources/                        # 数据资源
    ├── codex_entries/                # 图鉴词条数据
    │   ├── special_relativity.tres
    │   ├── general_relativity.tres
    │   ├── quantum_gravity.tres
    │   └── entropy_cosmology.tres
    ├── level_data/                   # 关卡配置
    └── dialogue/                     # NPC对话文本
```

---

## 核心架构决策

### 1. 全局时间管理系统（time_manager.gd）

这是整个游戏最关键的系统。所有物体的时间流速由 `TimeManager` 统一管理，每个物体有独立的 `time_scale` 属性。

```gdscript
# 每个可受时间影响的物体都应实现此接口
class_name TimeAffectedBody
extends Node2D

var local_time_scale: float = 1.0  # 相对场景基准时间的倍数

func get_effective_time_scale() -> float:
    # 考虑速度时间膨胀 + 引力时间膨胀 + 全局熵减速
    return TimeManager.calculate_time_scale(self)
```

**关键规则**：
- 玩家角色的 **输入响应绝不受 time_scale 影响**（通过 `_process` 而非 `_physics_process` 处理输入，或使用 `Engine.time_scale` 局部控制）
- 场景物体（平台、NPC）的动画/运动受 `time_scale` 影响
- 画面特效（色彩偏移、畸变）与 `time_scale` 绑定

### 2. 玩家操作即时响应原则

```gdscript
# Player.gd - 正确做法
func _process(delta: float) -> void:
    # 输入处理始终使用实时delta
    handle_input()

func _physics_process(delta: float) -> void:
    # 物理计算使用时间膨胀后的delta
    var dilated_delta = delta * TimeManager.get_player_time_scale()
    apply_movement(dilated_delta)
    update_animation_speed()  # 动画速度反映时间膨胀
```

### 3. 虫洞CTC回溯系统

虫洞时间差通过**场景状态快照**实现，而非全局时间回溯：

```gdscript
class_name WormholePair
extends Node2D

var portal_a: WormholePortal
var portal_b: WormholePortal
var time_offset: float = 0.0  # 穿越AB产生的时间差（秒）
var past_snapshot: SceneSnapshot  # 过去场景状态快照

func travel(from: WormholePortal, to: WormholePortal, traveler: Node2D) -> void:
    if time_offset != 0.0:
        # 穿越到过去：激活预录的快照副本
        past_snapshot.activate()
    # 将traveler传送到to的位置
    _teleport(traveler, to.global_position)
```

### 4. 结局判定系统

结局**不通过显式选择按钮触发**，而是基于全局行为统计：

```gdscript
# player_metrics.gd
var wormhole_loop_count: int = 0          # CTC回溯次数
var entropy_resist_count: int = 0         # 局部熵减干预次数
var bottom_layer_idle_time: float = 0.0   # 在底层静止空间的停留时间
var time_fragments_repaired: int = 0      # 修复时空碎片数量

func determine_ending() -> String:
    if wormhole_loop_count >= 3:
        return "closed_loop_prison"
    elif bottom_layer_idle_time > 60.0 and entropy_resist_count < 3:
        return "source_insight"
    else:
        return "toward_future"
```

---

## 物理机制实现要点

### 世界1：速度-时间耦合

```gdscript
# speed_time_coupling.gd
const LIGHT_SPEED: float = 1000.0  # 游戏内光速值
const SPEED_REDLINE: float = 0.99 * LIGHT_SPEED

func calculate_speed_dilation(velocity: Vector2) -> float:
    var speed = velocity.length()
    if speed >= SPEED_REDLINE:
        return INF  # 触发弹回
    return 1.0 / sqrt(1.0 - (speed * speed) / (LIGHT_SPEED * LIGHT_SPEED))
```

- 画面效果：速度越高 → 横向压缩（尺缩效应shader）+ 蓝移色调
- 光速红线：实体边界碰撞体，接触时播放弹回动画+红移特效
- 光锥：用Area2D检测玩家是否超出未来光锥区域

### 世界2：引力时间膨胀

```gdscript
# gravity_time_dilation.gd
func get_gravitational_time_dilation(position: Vector2, mass: float, center: Vector2) -> float:
    var r = position.distance_to(center)
    if r < SCHWARZSCHILD_RADIUS:  # 事件视界内
        return 0.0  # 时间停滞
    return sqrt(1.0 - (2.0 * G * mass) / (r * C_SQUARED))
```

- 视觉：Shader实现画面向引力源扭曲畸变
- 黑洞边缘：`time_scale` 趋近于0，但玩家操作仍即时

### 世界3：量子裂隙

```gdscript
# quantum_fissure.gd
var lifetime: float = 3.0
var warning_time: float = 0.5  # 出现前预兆粒子汇聚
var is_stable: bool = false

func _ready():
    # 播放预兆粒子效果0.5秒
    show_warning_particles()
    await get_tree().create_timer(warning_time).timeout
    activate_fissure()
    await get_tree().create_timer(lifetime).timeout
    if not is_stable:
        collapse()

func observe_extend():  # 玩家按观测键
    is_stable = true
    lifetime += 2.0
    # 播放稳定化特效
```

### 世界4：熵增系统

```gdscript
# entropy_system.gd
const GLOBAL_ENTROPY_RATE: float = 0.01  # 全局熵增速
var local_order_resources: int = 3       # 玩家可用的局部秩序干预次数

func _process(delta):
    global_entropy += GLOBAL_ENTROPY_RATE * delta
    # 根据熵值逐步崩坏场景平台
    for platform in entropy_platforms:
        platform.update_decay(global_entropy)
```

---

## Shader速查

### 引力透镜畸变Shader（gravitational_lens.gdshader）

```
shader_type canvas_item;

uniform vec2 black_hole_center;
uniform float distortion_strength;

void fragment() {
    vec2 uv = FRAGCOORD.xy / (1.0 / TEXTURE_PIXEL_SIZE);
    vec2 delta = uv - black_hole_center;
    float dist = length(delta);
    if (dist < 0.01) dist = 0.01;
    vec2 offset = normalize(delta) * distortion_strength / dist;
    COLOR = texture(TEXTURE, UV + offset * TEXTURE_PIXEL_SIZE);
}
```

### 时间膨胀色彩偏移（time_warp.gdshader）

```
shader_type canvas_item;

uniform float time_dilation_factor; // <1 = 红移, >1 = 蓝移

void fragment() {
    vec4 col = texture(TEXTURE, UV);
    float shift = (1.0 - time_dilation_factor) * 0.1;
    col.r += shift;  // 红移
    col.b -= shift;
    COLOR = col;
}
```

---

## 关卡设计规范

### 谜题设计模板

每个谜题应包含以下要素：
1. **物理机制**：明确本谜题利用的物理原理
2. **学习目标**：玩家通过本谜题理解什么概念
3. **解法步骤**：最多3-4步，避免过度复杂
4. **失败边界**：失败后重置条件（无惩罚）
5. **图鉴触发点**：解谜后解锁对应词条

### 难度梯度

| 世界 | 操作难度 | 认知难度 | 关卡数 |
|---|---|---|---|
| W1 | 低 | 中 | 3谜题 |
| W2 | 中 | 中高 | 2谜题+1BOSS |
| W3 | 高 | 高 | 3谜题 |
| W4 | 低 | 高（思辨） | 3层探索 |

---

## 命名约定

- **文件命名**：`snake_case`（如 `time_dilation.gd`）
- **场景命名**：`snake_case.tscn`
- **类名**：`PascalCase`（如 `TimeManager`）
- **信号**：过去式动词（如 `time_dilated`, `wormhole_entered`）
- **常量**：`UPPER_SNAKE_CASE`
- **导出变量**：分组并添加注释

```gdscript
# Good
@export_category("Time Dilation")
@export var base_time_scale: float = 1.0
@export var max_dilation: float = 10.0

# Avoid
@export var ts: float = 1.0
```

---

## 禁止事项（反模式）

- ❌ 让玩家操作出现延迟（哪怕是为了表现时间膨胀）
- ❌ 随机性过强的谜题解法（量子裂隙必须有预兆提示）
- ❌ 显式的结局选择按钮（结局必须由行为触发）
- ❌ 大段文字说明物理概念（交给图鉴系统）
- ❌ 物理原理上的明显错误（参考 `docs/physics-reference.md` 校验）
- ❌ 全局 `Engine.time_scale` 直接修改（会影响所有节点，改用局部时间系统）

---

## 测试与验证清单

### 机制验证
- [ ] 光速红线是否100%无法穿越？
- [ ] 虫洞CTC回溯是否正确重建过去场景？
- [ ] 接触“过去的自己”是否稳定触发悖论重置？
- [ ] 量子裂隙预兆是否始终在裂隙出现前播放？

### 体验验证
- [ ] 玩家操作是否始终即时响应？
- [ ] 图鉴解锁是否在解谜后正确触发？
- [ ] 结局判定条件是否在预期行为下触发？
- [ ] 无软锁定（玩家永远可以重置或继续）？

### 物理准确性
- [ ] 所有机制对应真实物理概念？
- [ ] 图鉴词条解释无科学性错误？
- [ ] 彩蛋/假说是否标注“非科学实证”？

---

## 总结

本项目试图在游戏性与物理教育之间找到精确平衡。所有开发决策应遵循一个准则：

> **玩家在解开谜题的瞬间，应该已经直觉性地理解了相对论。**

如有任何机制设计偏离此准则，请重新审视实现方式。