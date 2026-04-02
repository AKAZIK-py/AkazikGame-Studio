# EnemySelectPanel.gd
# 对手选择面板
# 允许玩家选择战斗对手（竖向紧凑设计）
class_name EnemySelectPanel
extends Control

# PRODUCTION CODE - V-Tacit Enemy Selection UI

## 信号：选择对手
signal enemy_selected(index: int)

## 战斗系统引用
@export var battle_system: BattleSystem

## 对手按钮容器（竖向）
var _button_container: VBoxContainer

## 当前选中的标签
var _current_label: Label


func _ready() -> void:
	# 立即创建UI
	_create_ui()
	print("EnemySelectPanel: Initialized")


func _create_ui() -> void:
	# 背景（苹果风格：圆角、半透明）
	var bg := ColorRect.new()
	bg.color = Color(0.12, 0.12, 0.16, 0.92)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	# 圆角
	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color = Color(0.12, 0.12, 0.16, 0.92)
	bg_style.set_corner_radius_all(8)
	add_child(bg)

	# 主容器（垂直布局）
	var main_vbox := VBoxContainer.new()
	main_vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	main_vbox.add_theme_constant_override("separation", 6)
	# 内边距
	main_vbox.offset_left = 8
	main_vbox.offset_right = -8
	main_vbox.offset_top = 6
	main_vbox.offset_bottom = -6
	add_child(main_vbox)

	# 标题行
	var title := Label.new()
	title.text = "选择对手"
	title.add_theme_font_size_override("font_size", 13)
	title.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(title)

	# 当前选中显示
	_current_label = Label.new()
	_current_label.add_theme_font_size_override("font_size", 12)
	_current_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	_current_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(_current_label)

	# 按钮容器（竖向）
	_button_container = VBoxContainer.new()
	_button_container.alignment = BoxContainer.ALIGNMENT_CENTER
	_button_container.add_theme_constant_override("separation", 4)
	main_vbox.add_child(_button_container)

	# 刷新按钮列表
	refresh_buttons()


func refresh_buttons() -> void:
	# 检查容器是否存在
	if _button_container == null:
		push_error("EnemySelectPanel: _button_container is null!")
		return

	# 清空现有按钮
	for child in _button_container.get_children():
		child.queue_free()

	if battle_system == null:
		return

	var presets := battle_system.get_enemy_presets()
	var selected := battle_system.get_selected_enemy()

	# 更新当前选中标签
	if _current_label:
		_current_label.text = "%s" % selected["name"]

	for i in range(presets.size()):
		var preset := presets[i]
		var btn := Button.new()
		btn.text = preset["name"]
		btn.custom_minimum_size = Vector2(100, 24)
		btn.add_theme_font_size_override("font_size", 11)

		# 苹果风格：扁平设计
		var normal_style := StyleBoxFlat.new()
		normal_style.set_corner_radius_all(4)

		# 高亮当前选择
		if preset["name"] == selected["name"]:
			normal_style.bg_color = Color(0.25, 0.55, 0.85, 0.9)  # 苹果蓝
			btn.add_theme_color_override("font_color", Color.WHITE)
		else:
			normal_style.bg_color = Color(0.2, 0.2, 0.25, 0.6)
			btn.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))

		btn.add_theme_stylebox_override("normal", normal_style)
		btn.add_theme_stylebox_override("hover", _create_hover_style())

		btn.pressed.connect(_on_button_pressed.bind(i))
		_button_container.add_child(btn)


func _create_hover_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.35, 0.35, 0.4, 0.8)
	style.set_corner_radius_all(4)
	return style


func _on_button_pressed(index: int) -> void:
	if battle_system:
		battle_system.select_enemy(index)
		refresh_buttons()
		enemy_selected.emit(index)


## 显示面板
func show_panel() -> void:
	show()
	refresh_buttons()


## 隐藏面板
func hide_panel() -> void:
	hide()
