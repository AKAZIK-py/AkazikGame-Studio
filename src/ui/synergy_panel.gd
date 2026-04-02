# SynergyPanel.gd
# 羁绊状态面板
# 显示当前激活的羁绊和进度
class_name SynergyPanel
extends Control

# PRODUCTION CODE - V-Tacit Synergy Feedback UI

## 羁绊检测系统引用
@export var detection_system: SynergyDetectionSystem

## 容器
@onready var _container: VBoxContainer = $ScrollContainer/VBoxContainer


func _ready() -> void:
	call_deferred("_delayed_init")


func _delayed_init() -> void:
	if detection_system:
		if not detection_system.synergies_changed.is_connected(_on_synergies_changed):
			detection_system.synergies_changed.connect(_on_synergies_changed)
		print("SynergyPanel: Connected to detection_system")
	else:
		push_warning("SynergyPanel: detection_system is null")


## 更新羁绊显示
func update_display() -> void:
	if detection_system == null:
		return

	# 检查容器是否存在
	if _container == null:
		push_error("SynergyPanel: _container is null! Check scene node path.")
		return

	# 清空现有内容
	for child in _container.get_children():
		child.queue_free()

	# 获取羁绊进度
	var progress := detection_system.get_all_synergy_progress()

	for synergy_id in progress:
		var data: Dictionary = progress[synergy_id]
		_create_synergy_entry(synergy_id, data)


func _create_synergy_entry(synergy_id: String, data: Dictionary) -> void:
	if _container == null:
		return

	var label := Label.new()
	var display_name: String = data.get("display_name", synergy_id)
	var count: int = data.get("count", 0)
	var level: int = data.get("level", 0)
	var thresholds: Array = data.get("thresholds", [])
	var is_active: bool = data.get("is_active", false)

	var text := display_name + ": "

	if is_active:
		text += "Lv.%d (%d人)" % [level, count]
		label.add_theme_color_override("font_color", Color(0.3, 0.8, 0.4))
	else:
		var next_threshold: int = data.get("next_threshold", thresholds[0] if thresholds.size() > 0 else 0)
		text += "%d/%d" % [count, next_threshold]
		label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))

	label.text = text
	_container.add_child(label)


func _on_synergies_changed(_active_synergies: Dictionary) -> void:
	update_display()
