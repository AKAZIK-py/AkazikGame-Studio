# BattleControlPanel.gd
# 战斗控制面板
# 提供战斗加速和跳过功能
class_name BattleControlPanel
extends Control

# PRODUCTION CODE - V-Tacit Battle Control UI

## 信号：请求加速
signal speed_changed(speed: float)

## 信号：请求跳过
signal skip_requested()

## 当前速度
var _current_speed: float = 1.0

## 速度选项
const SPEED_OPTIONS: Array[float] = [1.0, 2.0, 4.0]

## 速度按钮组
var _speed_buttons: Array[Button] = []

## 跳过按钮
var _skip_button: Button


func _ready() -> void:
	_create_ui()


func _create_ui() -> void:
	# 背景
	var bg := ColorRect.new()
	bg.color = Color(0.1, 0.1, 0.14, 0.95)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# 主容器
	var hbox := HBoxContainer.new()
	hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	hbox.offset_left = 10
	hbox.offset_right = -10
	hbox.offset_top = 5
	hbox.offset_bottom = -5
	hbox.add_theme_constant_override("separation", 8)
	add_child(hbox)

	# 速度标签
	var speed_label := Label.new()
	speed_label.text = "速度:"
	speed_label.add_theme_font_size_override("font_size", 12)
	speed_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	hbox.add_child(speed_label)

	# 速度按钮（1x, 2x, 4x）
	for i in range(SPEED_OPTIONS.size()):
		var speed := SPEED_OPTIONS[i]
		var btn := Button.new()
		btn.text = "%dx" % int(speed)
		btn.custom_minimum_size = Vector2(40, 28)
		btn.toggle_mode = true

		# 样式
		var normal_style := StyleBoxFlat.new()
		normal_style.set_corner_radius_all(4)

		if speed == _current_speed:
			normal_style.bg_color = Color(0.25, 0.55, 0.85)
			btn.button_pressed = true
		else:
			normal_style.bg_color = Color(0.2, 0.2, 0.25)

		btn.add_theme_stylebox_override("normal", normal_style)
		btn.add_theme_font_size_override("font_size", 11)
		btn.pressed.connect(_on_speed_button_pressed.bind(speed, i))

		hbox.add_child(btn)
		_speed_buttons.append(btn)

	# 分隔
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(spacer)

	# 跳过按钮
	_skip_button = Button.new()
	_skip_button.text = "跳过战斗"
	_skip_button.custom_minimum_size = Vector2(80, 28)

	var skip_style := StyleBoxFlat.new()
	skip_style.bg_color = Color(0.6, 0.3, 0.2)
	skip_style.set_corner_radius_all(4)
	_skip_button.add_theme_stylebox_override("normal", skip_style)
	_skip_button.add_theme_font_size_override("font_size", 11)
	_skip_button.pressed.connect(_on_skip_pressed)

	hbox.add_child(_skip_button)


func _on_speed_button_pressed(speed: float, index: int) -> void:
	_current_speed = speed

	# 更新按钮状态
	for i in range(_speed_buttons.size()):
		var btn := _speed_buttons[i]
		var style := StyleBoxFlat.new()
		style.set_corner_radius_all(4)

		if i == index:
			style.bg_color = Color(0.25, 0.55, 0.85)
			btn.button_pressed = true
		else:
			style.bg_color = Color(0.2, 0.2, 0.25)
			btn.button_pressed = false

		btn.add_theme_stylebox_override("normal", style)

	speed_changed.emit(speed)


func _on_skip_pressed() -> void:
	skip_requested.emit()


## 显示面板
func show_panel() -> void:
	show()


## 隐藏面板
func hide_panel() -> void:
	hide()


## 重置速度到默认
func reset_speed() -> void:
	_current_speed = 1.0
	_on_speed_button_pressed(1.0, 0)
