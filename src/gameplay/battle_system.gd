# BattleSystem.gd
# 战斗系统
# 计算双方阵容胜率，执行战斗判定
class_name BattleSystem
extends Node

# PRODUCTION CODE - V-Tacit Battle System
# Implements: design/gdd/battle-system.md

## 信号：战斗开始
signal battle_started()

## 信号：战斗完成
signal battle_completed(result: Dictionary)


## 属性计算系统引用
@export var attribute_calc: AttributeCalculationSystem

## 羁绊效果系统引用
@export var synergy_effect: SynergyEffectSystem

## 羁绊检测系统引用
@export var synergy_detection: SynergyDetectionSystem

## 棋盘系统引用
@export var board_system: BoardSystem


## 定位系数
const ROLE_COEFFICIENTS: Dictionary = {
	"output": 1.1,
	"tank": 1.0,
	"support": 0.9,
	"core": 1.2,
	"warrior": 1.0,
	"mage": 1.05
}

## 最大羁绊系数（详见 design/gdd/battle-system.md）
const MAX_SYNERGY_COEFFICIENT := 3.0

## 敌方阵容数据
var _enemy_instances: Array[CharacterInstance] = []

## 战斗结果缓存
var _last_battle_result: Dictionary = {}

## 当前选择的对手索引
var _selected_enemy_index: int = 0

## 对手预设列表
var ENEMY_PRESETS: Array[Dictionary] = [
	{"name": "歌手队", "characters": ["xiao_ke", "ze_yin", "lu_zao", "you_en"], "difficulty": "中等"},
	{"name": "VR小队", "characters": ["xiao_ke", "a_zi", "qi_hai"], "difficulty": "简单"},
	{"name": "糖分小队", "characters": ["xue_gao", "bai_shen_yao", "yong_chu_ta_fei"], "difficulty": "中等"},
	{"name": "偶像阵", "characters": ["lu_lulu", "tian_dou", "xing_tong"], "difficulty": "简单"},
	{"name": "PSP组合", "characters": ["dong_ai_li", "bai_shen_yao", "hirro"], "difficulty": "困难"},
	{"name": "随机阵容", "characters": [], "difficulty": "未知"},
]


#region 公共接口

## 计算胜率
func calculate_win_rate(player_team: Array, enemy_team: Array) -> float:
	var player_power := calculate_team_power(player_team)
	var enemy_power := calculate_team_power(enemy_team)

	if player_power <= 0 and enemy_power <= 0:
		return 0.5  # 双方都无战力，50%胜率

	if enemy_power <= 0:
		return 1.0  # 敌方无战力，必胜

	if player_power <= 0:
		return 0.0  # 玩家无战力，必败

	var win_rate := player_power / (player_power + enemy_power)
	return minf(maxf(win_rate, 0.0), 1.0)


## 计算队伍战力
func calculate_team_power(team: Array) -> float:
	var total_power := 0.0

	for instance in team:
		if instance == null:
			continue
		total_power += calculate_character_power(instance)

	return total_power


## 计算单个角色战力
func calculate_character_power(instance: CharacterInstance) -> float:
	if instance == null:
		return 0.0

	var char_data := instance.get_character_data()
	if char_data == null:
		return 0.0

	var attack := float(instance.current_attack)
	var health := float(instance.max_health)

	# 定位系数
	var role_coeff: float = ROLE_COEFFICIENTS.get(char_data.role, 1.0)

	# 羁绊系数（基于激活的羁绊数量和等级）
	var synergy_coeff: float = _calculate_synergy_coefficient(instance)

	# MVP简化：不使用技能系数，预留给MVP+版本
	# 详见 design/gdd/battle-system.md

	# 位置加成
	var position_coeff := 1.0
	if attribute_calc:
		var pos_eval := attribute_calc.get_position_evaluation(instance)
		var win_rate_bonus: float = pos_eval.get("win_rate_bonus", 0.0)
		# 将胜率加成转换为战力系数
		position_coeff = 1.0 + win_rate_bonus

	# 战力公式（MVP简化版）
	var power: float = attack * health * role_coeff * synergy_coeff * position_coeff

	return power


## 执行战斗计算
func execute_battle() -> Dictionary:
	if board_system == null:
		return {}

	# 获取玩家队伍
	var player_team := board_system.get_all_characters()
	if player_team.is_empty():
		push_warning("BattleSystem: Player team is empty")
		return {"error": "empty_team"}

	# 生成敌方队伍
	_enemy_instances = _generate_enemy_team()
	if _enemy_instances.is_empty():
		push_warning("BattleSystem: Failed to generate enemy team")
		return {"error": "no_enemy"}

	# 将敌方队伍放置在敌方区域并更新GameState
	_place_enemies_on_board()

	# 计算双方战力
	var player_power := calculate_team_power(player_team)
	var enemy_power := calculate_team_power(_enemy_instances)

	# 计算胜率
	var win_rate := calculate_win_rate(player_team, _enemy_instances)

	# 判定胜负
	var roll := randf()
	var player_wins := roll < win_rate

	# 构建结果
	var result := {
		"player_power": player_power,
		"enemy_power": enemy_power,
		"win_rate": win_rate,
		"win_rate_percent": snappedf(win_rate * 100, 0.1),
		"player_wins": player_wins,
		"player_team_size": player_team.size(),
		"enemy_team_size": _enemy_instances.size(),
		"enemy_team_name": _last_battle_result.get("enemy_name", "未知阵容")
	}

	# 存储结果
	_last_battle_result = result
	GameState.set_battle_result(result)

	battle_completed.emit(result)
	return result


## 获取上次战斗结果
func get_last_battle_result() -> Dictionary:
	return _last_battle_result


## 获取敌方队伍
func get_enemy_team() -> Array[CharacterInstance]:
	return _enemy_instances


## 清空敌方队伍
func clear_enemy_team() -> void:
	_enemy_instances.clear()
	GameState.clear_enemy_board()


## 获取所有对手预设
func get_enemy_presets() -> Array[Dictionary]:
	return ENEMY_PRESETS


## 选择对手
func select_enemy(index: int) -> void:
	if index >= 0 and index < ENEMY_PRESETS.size():
		_selected_enemy_index = index


## 获取当前选择的对手
func get_selected_enemy() -> Dictionary:
	return ENEMY_PRESETS[_selected_enemy_index]


#endregion


#region 内部方法

func _place_enemies_on_board() -> void:
	# 将敌方实例存储到GameState的敌方棋盘中
	GameState.set_enemy_board(_enemy_instances)


func _calculate_synergy_coefficient(instance: CharacterInstance) -> float:
	if synergy_detection == null:
		return 1.0

	var char_data := instance.get_character_data()
	if char_data == null:
		return 1.0

	var coeff := 1.0

	# 检查角色涉及的激活羁绊
	for synergy_id in synergy_detection.get_active_synergies():
		if synergy_id in char_data.synergy_tags:
			var level := synergy_detection.get_synergy_level(synergy_id)
			# 每级羁绊增加5%系数
			coeff += level * 0.05

	# EOE姐妹特殊处理
	if char_data.id == "lu_zao" or char_data.id == "you_en":
		if synergy_detection.is_eoe_sisters_active():
			coeff *= 1.3  # 额外加成

	return minf(coeff, MAX_SYNERGY_COEFFICIENT)


func _generate_enemy_team() -> Array[CharacterInstance]:
	var team := _select_enemy_preset()

	if team.is_empty():
		# 如果预设阵容失败，生成随机阵容
		team = _generate_random_enemy_team()

	# 应用羁绊效果
	if synergy_effect and synergy_detection:
		# 临时设置敌方棋盘（用于羁绊计算）
		for instance in team:
			synergy_effect.apply_synergy_effects(instance)

	return team


func _select_enemy_preset() -> Array[CharacterInstance]:
	# 使用选择的预设或随机
	var preset: Dictionary
	if _selected_enemy_index >= 0 and _selected_enemy_index < ENEMY_PRESETS.size():
		preset = ENEMY_PRESETS[_selected_enemy_index]
	else:
		# 随机选择
		var index := randi() % ENEMY_PRESETS.size()
		preset = ENEMY_PRESETS[index]

	var char_ids: Array = preset["characters"]

	# 随机阵容特殊处理
	if char_ids.is_empty():
		return _generate_random_enemy_team()

	_last_battle_result["enemy_name"] = preset["name"]

	var instances: Array[CharacterInstance] = []

	# 收集所有角色数据
	var char_data_list: Array[CharacterData] = []
	for char_id in char_ids:
		var char_data := CharacterRegistry.get_character(char_id)
		if char_data != null:
			char_data_list.append(char_data)

	# AI智能站位：按定位分配位置
	instances = _ai_position_characters(char_data_list)

	return instances


## AI智能站位：根据角色定位优化位置
func _ai_position_characters(characters: Array[CharacterData]) -> Array[CharacterInstance]:
	var instances: Array[CharacterInstance] = []

	# 分类角色
	var tanks: Array[CharacterData] = []
	var others: Array[CharacterData] = []

	for char_data in characters:
		if char_data.role == "tank":
			tanks.append(char_data)
		else:
			others.append(char_data)

	# 敌方区域：行0-1为前排，行2-3为后排
	var front_rows := [0, 1]
	var back_rows := [2, 3]

	# 坦克放在前排
	var tank_positions: Array[Vector2i] = []
	for row in front_rows:
		for col in range(board_system.board_cols):
			tank_positions.append(Vector2i(col, row))

	# 其他角色放在后排
	var other_positions: Array[Vector2i] = []
	for row in back_rows:
		for col in range(board_system.board_cols):
			other_positions.append(Vector2i(col, row))

	# 放置坦克
	for i in range(tanks.size()):
		if i < tank_positions.size():
			var pos := tank_positions[i]
			var instance := CharacterInstance.from_data(tanks[i], pos)
			instances.append(instance)

	# 放置其他角色
	for i in range(others.size()):
		if i < other_positions.size():
			var pos := other_positions[i]
			var instance := CharacterInstance.from_data(others[i], pos)
			instances.append(instance)

	return instances


func _generate_random_enemy_team() -> Array[CharacterInstance]:
	var instances: Array[CharacterInstance] = []
	var team_size := randi_range(3, 4)

	_last_battle_result["enemy_name"] = "随机阵容"

	for i in range(team_size):
		# 随机抽取一个角色
		var all_chars := CharacterRegistry.get_all_characters()
		if all_chars.is_empty():
			continue

		var idx := randi() % all_chars.size()
		var char_data: CharacterData = all_chars[idx]

		# 放置在敌方区域
		var col := i % board_system.board_cols
		var row := i / board_system.board_cols
		if row >= BoardSystem.PLAYER_ZONE_START:
			row = 0

		var instance := CharacterInstance.from_data(char_data, Vector2i(col, row))
		instances.append(instance)

	return instances


#endregion
