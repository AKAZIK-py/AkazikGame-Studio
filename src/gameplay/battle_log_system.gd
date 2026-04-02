# BattleLogSystem.gd
# 战斗日志系统
# 记录战斗事件并提供查询接口
class_name BattleLogSystem
extends Node

# PRODUCTION CODE - V-Tacit Battle Log
# Implements: design/gdd/auto-battle-system.md

## 信号：新日志事件添加
signal log_event_added(event: Dictionary)

## 信号：日志清空
signal log_cleared()

## 最大日志条数
@export var max_log_entries: int = 100

## 日志存储
var _log_entries: Array[Dictionary] = []

## 事件类型定义
enum EventType {
	TURN_START,
	TURN_END,
	MOVE,
	ATTACK,
	SKILL,
	DEATH,
	BATTLE_START,
	BATTLE_END
}


#region 公共接口

## 添加日志事件
func add_event(event_type: EventType, data: Dictionary) -> void:
	var event := {
		"type": event_type,
		"data": data,
		"timestamp": Time.get_ticks_msec(),
		"turn": data.get("turn", 0)
	}

	_log_entries.append(event)

	# 限制日志大小
	if _log_entries.size() > max_log_entries:
		_log_entries.remove_at(0)

	log_event_added.emit(event)


## 获取所有日志
func get_all_logs() -> Array[Dictionary]:
	return _log_entries


## 获取最近N条日志
func get_recent_logs(count: int) -> Array[Dictionary]:
	var start := maxi(0, _log_entries.size() - count)
	return _log_entries.slice(start)


## 获取指定回合的日志
func get_logs_by_turn(turn: int) -> Array[Dictionary]:
	return _log_entries.filter(func(e): return e.turn == turn)


## 获取指定类型的日志
func get_logs_by_type(event_type: EventType) -> Array[Dictionary]:
	return _log_entries.filter(func(e): return e.type == event_type)


## 清空日志
func clear_logs() -> void:
	_log_entries.clear()
	log_cleared.emit()


## 格式化日志事件为文本
func format_event(event: Dictionary) -> String:
	var event_type: int = event.get("type", -1)
	var data: Dictionary = event.get("data", {})

	match event_type:
		EventType.TURN_START:
			return "回合 %d 开始" % data.get("turn", 0)

		EventType.TURN_END:
			return "回合 %d 结束" % data.get("turn", 0)

		EventType.MOVE:
			var char_name := _get_character_name(String(data.get("character", "")))
			var from: Array = data.get("from", [0, 0])
			var to: Array = data.get("to", [0, 0])
			return "%s 移动 (%d,%d) → (%d,%d)" % [char_name, from[0], from[1], to[0], to[1]]

		EventType.ATTACK:
			var attacker := _get_character_name(String(data.get("attacker", "")))
			var target := _get_character_name(String(data.get("target", "")))
			var damage: int = data.get("damage", 0)
			return "%s 攻击 %s，造成 %d 点伤害" % [attacker, target, damage]

		EventType.SKILL:
			var caster := _get_character_name(String(data.get("caster", "")))
			var skill: String = data.get("skill", "")
			var target := _get_character_name(String(data.get("target", "")))
			var damage: int = data.get("damage", 0)
			return "%s 使用 %s 对 %s 造成 %d 点伤害" % [caster, skill, target, damage]

		EventType.DEATH:
			var char_name := _get_character_name(String(data.get("character", "")))
			var killer := _get_character_name(String(data.get("killer", "")))
			return "%s 被 %s 击败" % [char_name, killer]

		EventType.BATTLE_START:
			return "战斗开始"

		EventType.BATTLE_END:
			var winner: String = data.get("winner", "unknown")
			var turns: int = data.get("turns", 0)
			var winner_text := "玩家" if winner == "player" else "敌方" if winner == "enemy" else "平局"
			return "战斗结束: %s获胜 (共%d回合)" % [winner_text, turns]

		_:
			return "未知事件"


#endregion


#region 辅助方法

## 获取角色名称
func _get_character_name(character_id: String) -> String:
	var char_data := CharacterRegistry.get_character(character_id)
	if char_data:
		return char_data.display_name
	return character_id


#endregion
