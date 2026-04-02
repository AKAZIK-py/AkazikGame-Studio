# BattleResultPanel.gd
# 战斗结果面板
# 显示战斗胜率、结果和继续按钮
class_name BattleResultPanel
extends Control

# PRODUCTION CODE - V-Tacit Battle Result UI
# Implements: design/gdd/battle-result.md

## 信号：继续按钮点击
signal continue_pressed()

## 信号：重置按钮点击
signal reset_pressed()


## 战斗系统引用
@export var battle_system: BattleSystem

## 标题标签
@onready var _title_label: Label = $VBoxContainer/TitleLabel

## 胜率标签
@onready var _win_rate_label: Label = $VBoxContainer/WinRateLabel

## 结果标签
@onready var _result_label: Label = $VBoxContainer/ResultLabel

## 战力对比标签
@onready var _power_label: Label = $VBoxContainer/PowerLabel

## 继续按钮
@onready var _continue_button: Button = $VBoxContainer/ButtonContainer/ContinueButton

## 重置按钮
@onready var _reset_button: Button = $VBoxContainer/ButtonContainer/ResetButton

## 当前战斗结果
var _current_result: Dictionary = {}


func _ready() -> void:
	hide()
	if _continue_button:
		_continue_button.pressed.connect(_on_continue_pressed)
	if _reset_button:
		_reset_button.pressed.connect(_on_reset_pressed)


## 显示战斗结果
func show_result(result: Dictionary) -> void:
	_current_result = result

	# 更新胜率
	var win_rate_percent: float = result.get("win_rate_percent", 0.0)
	if _win_rate_label:
		_win_rate_label.text = "胜率: %.1f%%" % win_rate_percent

	# 更新结果
	var player_wins: bool = result.get("player_wins", false)
	if _result_label:
		if player_wins:
			_result_label.text = "胜利！"
			_result_label.add_theme_color_override("font_color", Color(0.3, 0.8, 0.3))
		else:
			_result_label.text = "失败..."
			_result_label.add_theme_color_override("font_color", Color(0.8, 0.3, 0.3))

	# 更新战力对比
	var player_power: float = result.get("player_power", 0)
	var enemy_power: float = result.get("enemy_power", 0)
	var enemy_name: String = result.get("enemy_team_name", "未知阵容")

	if _power_label:
		_power_label.text = "我方战力: %d vs 敌方战力: %d (%s)" % [int(player_power), int(enemy_power), enemy_name]

	# 更新标题
	if _title_label:
		if player_wins:
			_title_label.text = "战斗胜利"
		else:
			_title_label.text = "战斗失败"

	show()


## 隐藏面板
func hide_result() -> void:
	hide()


## 清空结果
func clear_result() -> void:
	_current_result = {}
	if _win_rate_label:
		_win_rate_label.text = ""
	if _result_label:
		_result_label.text = ""
	if _power_label:
		_power_label.text = ""
	hide()


#region 信号处理

func _on_continue_pressed() -> void:
	continue_pressed.emit()


func _on_reset_pressed() -> void:
	reset_pressed.emit()


#endregion
