# BattleLogPanel.gd
# 战斗日志面板
# 显示战斗过程中的事件日志
class_name BattleLogPanel
extends Control

# PRODUCTION CODE - V-Tacit Battle Log UI

## 战斗日志系统引用
@export var log_system: BattleLogSystem

## 最大显示条数
@export var max_display_entries: int = 10

## 日志容器
var _log_container: VBoxContainer

## 滚动容器
var _scroll_container: ScrollContainer

## 日志标签数组
var _log_labels: Array[Label] = []


func _ready() -> void:
	_create_ui()

	if log_system:
		log_system.log_event_added.connect(_on_log_event_added)
		log_system.log_cleared.connect(_on_log_cleared)


func _create_ui() -> void:
	# 背景
	var bg := ColorRect.new()
	bg.color = Color(0.08, 0.08, 0.12, 0.9)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)

	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color = Color(0.08, 0.08, 0.12, 0.9)
	bg_style.set_corner_radius_all(6)
	bg_style.border_color = Color(0.3, 0.3, 0.35, 0.5)
	bg_style.set_border_width_all(1)
	bg.add_theme_stylebox_override("panel", bg_style)
	add_child(bg)

	# 主容器
	var main_vbox := VBoxContainer.new()
	main_vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	main_vbox.offset_left = 8
	main_vbox.offset_right = -8
	main_vbox.offset_top = 6
	main_vbox.offset_bottom = -6
	main_vbox.add_theme_constant_override("separation", 4)
	add_child(main_vbox)

	# 标题
	var title := Label.new()
	title.text = "战斗日志"
	title.add_theme_font_size_override("font_size", 12)
	title.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	main_vbox.add_child(title)

	# 滚动容器
	_scroll_container = ScrollContainer.new()
	_scroll_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll_container.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	main_vbox.add_child(_scroll_container)

	# 日志容器
	_log_container = VBoxContainer.new()
	_log_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_log_container.add_theme_constant_override("separation", 2)
	_scroll_container.add_child(_log_container)

	# 预创建日志标签
	for i in range(max_display_entries):
		var label := Label.new()
		label.add_theme_font_size_override("font_size", 10)
		label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.visible = false
		_log_container.add_child(label)
		_log_labels.append(label)


## 更新显示
func update_display() -> void:
	if log_system == null:
		return

	var logs := log_system.get_recent_logs(max_display_entries)

	# 更新标签
	for i in range(_log_labels.size()):
		if i < logs.size():
			var event: Dictionary = logs[logs.size() - 1 - i]  # 最新的在上面
			_log_labels[i].text = log_system.format_event(event)
			_log_labels[i].visible = true

			# 根据事件类型设置颜色
			_set_label_color(_log_labels[i], event.type)
		else:
			_log_labels[i].visible = false

	# 滚动到底部（显示最新）
	await get_tree().process_frame
	_scroll_container.scroll_vertical = _scroll_container.get_v_scroll_bar().max_value


## 设置标签颜色
func _set_label_color(label: Label, event_type: int) -> void:
	match event_type:
		BattleLogSystem.EventType.ATTACK:
			label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.3))
		BattleLogSystem.EventType.SKILL:
			label.add_theme_color_override("font_color", Color(0.5, 0.8, 1.0))
		BattleLogSystem.EventType.DEATH:
			label.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
		BattleLogSystem.EventType.BATTLE_END:
			label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.5))
		_:
			label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))


## 清空显示
func clear_display() -> void:
	for label in _log_labels:
		label.visible = false


#region 信号处理

func _on_log_event_added(_event: Dictionary) -> void:
	update_display()


func _on_log_cleared() -> void:
	clear_display()


#endregion


## 显示面板
func show_panel() -> void:
	show()
	update_display()


## 隐藏面板
func hide_panel() -> void:
	hide()
