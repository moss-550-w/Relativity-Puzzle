class_name CodexEntry
extends Resource
## 图鉴词条资源
## 每个词条是一个 .tres 文件，包含名称、描述、分类


@export var entry_id: String = ""
## 词条名称
@export var entry_name: String = ""
## 通俗解释（一句话）
@export var description: String = ""
## 分类
@export var category: String = ""
## 是否隐藏词条（需探索发现）
@export var is_hidden: bool = false
## 解锁提示文本
@export var unlock_hint: String = ""
