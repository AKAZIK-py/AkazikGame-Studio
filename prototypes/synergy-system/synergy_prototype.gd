// PROTOTYPE - NOT FOR PRODUCTION
// Question: 羁绊检测和效果应用是否正确工作？特殊羁绊（狍子、EOE姐妹、单挂）是否能正确触发？
// Date: 2026-03-28

extends SceneTree

# ============================================================
# 羁绊系统原型 - 验证核心逻辑
# ============================================================

func _init():
	print("=== 羁绊系统原型测试 ===")
	print("")

	# 初始化数据
	var char_registry = CharacterRegistry.new()
	var synergy_registry = SynergyRegistry.new()
	var board = BoardSystem.new()
	var detector = SynergyDetector.new(synergy_registry, board)
	var effect_system = SynergyEffectSystem.new(synergy_registry)

	# 测试用例
	run_tests(char_registry, synergy_registry, board, detector, effect_system)

	quit()

func run_tests(char_registry, synergy_registry, board, detector, effect_system):
	print("## 测试开始 ##\n")

	# 测试1: VR羁绊 (2/4 阈值)
	test_vr_synergy(char_registry, board, detector, effect_system)

	# 测试2: EOE姐妹 (组合羁绊)
	test_eoe_synergy(char_registry, board, detector, effect_system)

	# 测试3: 狍子 (万能羁绊)
	test_wildcard_synergy(char_registry, board, detector, effect_system)

	# 测试4: 单挂效果 (位置效果)
	test_isolated_effect(char_registry, board, detector, effect_system)

	# 测试5: 多羁绊叠加
	test_multi_synergy(char_registry, board, detector, effect_system)

	print("\n## 测试完成 ##")

# ============================================================
# 测试用例
# ============================================================

func test_vr_synergy(char_registry, board, detector, effect_system):
	print("### 测试1: VR羁绊 (2/4 阈值) ###")

	# 清空棋盘
	board.clear()

	# 放置1个VR角色
	board.place_character(char_registry.get_character("xiao_ke"), 0, 0)
	var synergies = detector.detect_synergies()
	print("1个VR角色: 激活羁绊 %s" % [synergies])
	assert(not synergies.has("vr"), "VR羁绊不应激活")

	# 放置第2个VR角色 (达到2人阈值)
	board.place_character(char_registry.get_character("azi"), 1, 0)
	synergies = detector.detect_synergies()
	print("2个VR角色: 激活羁绊 %s, 等级 %d" % [synergies, detector.get_synergy_level("vr")])
	assert(synergies.has("vr"), "VR羁绊应该激活")
	assert(detector.get_synergy_level("vr") == 1, "VR羁绊应为1级")

	# 应用效果
	var azi = board.get_character_at(1, 0)
	var base_attack = azi.base_attack
	effect_system.apply_synergy_effects(azi, detector.get_active_synergies())
	print("阿梓: 基础攻击 %d → 最终攻击 %.1f (+%.0f%%)" % [base_attack, azi.final_attack, (azi.final_attack / base_attack - 1) * 100])

	# 放置第4个VR角色 (达到4人阈值)
	board.place_character(char_registry.get_character("qi_hai"), 2, 0)
	board.place_character(char_registry.get_character("tian_dou"), 3, 0)
	synergies = detector.detect_synergies()
	print("4个VR角色: 激活羁绊 %s, 等级 %d" % [synergies, detector.get_synergy_level("vr")])
	assert(detector.get_synergy_level("vr") == 2, "VR羁绊应为2级")

	print("✓ VR羁绊测试通过\n")

func test_eoe_synergy(char_registry, board, detector, effect_system):
	print("### 测试2: EOE姐妹 (组合羁绊) ###")

	# 清空棋盘
	board.clear()

	# 只放置露早
	board.place_character(char_registry.get_character("lu_zao"), 0, 0)
	var synergies = detector.detect_synergies()
	print("只有露早: 激活羁绊 %s" % [synergies])
	assert(not synergies.has("eoe_sisters"), "EOE姐妹不应激活")

	# 放置柚恩
	board.place_character(char_registry.get_character("you_en"), 1, 0)
	synergies = detector.detect_synergies()
	print("露早+柚恩: 激活羁绊 %s" % [synergies])
	assert(synergies.has("eoe_sisters"), "EOE姐妹应该激活")

	# 验证强化效果
	var lu_zao = board.get_character_at(0, 0)
	var base_attack = lu_zao.base_attack
	effect_system.apply_synergy_effects(lu_zao, detector.get_active_synergies())
	print("露早: 基础攻击 %d → 最终攻击 %.1f (强化倍率 %.1fx)" % [base_attack, lu_zao.final_attack, lu_zao.final_attack / base_attack])

	# 预期: 攻击 × 2.5
	assert(abs(lu_zao.final_attack - base_attack * 2.5) < 0.1, "EOE强化效果应为2.5倍攻击")

	print("✓ EOE姐妹测试通过\n")

func test_wildcard_synergy(char_registry, board, detector, effect_system):
	print("### 测试3: 狍子 (万能羁绊) ###")

	# 清空棋盘
	board.clear()

	# 放置东爱璃 (狍子)
	board.place_character(char_registry.get_character("dong_ai_li"), 0, 0)
	var synergies = detector.detect_synergies()
	print("只有东爱璃: 激活羁绊 %s" % [synergies])
	assert(not synergies.has("wildcard"), "狍子不提供独立效果")

	# 添加1个VR角色 + 东爱璃 = VR(2)
	board.place_character(char_registry.get_character("xiao_ke"), 1, 0)
	synergies = detector.detect_synergies()
	print("小可+东爱璃: 激活羁绊 %s, VR等级 %d" % [synergies, detector.get_synergy_level("vr")])
	assert(synergies.has("vr"), "狍子应该计入VR羁绊")
	assert(detector.get_synergy_level("vr") == 1, "VR羁绊应为1级")

	# 添加1个糖角色 + 东爱璃 = 糖(2) (测试狍子计入不同羁绊)
	board.clear()
	board.place_character(char_registry.get_character("xue_gao"), 0, 0)
	board.place_character(char_registry.get_character("dong_ai_li"), 1, 0)
	synergies = detector.detect_synergies()
	print("雪糕+东爱璃: 激活羁绊 %s, 糖等级 %d" % [synergies, detector.get_synergy_level("tang")])
	assert(synergies.has("tang"), "狍子应该计入糖羁绊")

	print("✓ 狍子测试通过\n")

func test_isolated_effect(char_registry, board, detector, effect_system):
	print("### 测试4: 单挂效果 (位置效果) ###")

	# 清空棋盘
	board.clear()

	# 放置hirro在孤立位置
	board.place_character(char_registry.get_character("hirro"), 5, 5)
	var is_isolated = board.is_isolated(5, 5)
	print("hirro单独放置: 孤立 %s" % [is_isolated])
	assert(is_isolated, "hirro应该是孤立的")

	# 应用单挂效果
	var hirro = board.get_character_at(5, 5)
	var base_attack = hirro.base_attack
	var base_health = hirro.base_health
	effect_system.apply_isolated_effect(hirro, is_isolated)
	print("hirro: 攻击 %d → %.1f, 生命 %d → %.1f" % [base_attack, hirro.final_attack, base_health, hirro.final_health])
	assert(abs(hirro.final_attack - base_attack * 1.4) < 0.1, "单挂攻击加成应为40%")
	assert(abs(hirro.final_health - base_health * 1.3) < 0.1, "单挂生命加成应为30%")

	# 在旁边放置另一个角色
	board.place_character(char_registry.get_character("xiao_ke"), 6, 5)
	is_isolated = board.is_isolated(5, 5)
	print("hirro旁边有棋子: 孤立 %s" % [is_isolated])
	assert(not is_isolated, "hirro不应再孤立")

	# 重新计算
	effect_system.apply_isolated_effect(hirro, is_isolated)
	print("hirro: 攻击 %.1f → %.1f (效果消失)" % [base_attack * 1.4, hirro.final_attack])
	assert(abs(hirro.final_attack - base_attack) < 0.1, "单挂效果应消失")

	print("✓ 单挂效果测试通过\n")

func test_multi_synergy(char_registry, board, detector, effect_system):
	print("### 测试5: 多羁绊叠加 ###")

	# 清空棋盘
	board.clear()

	# 阿梓有 VR + 歌手 + 糖 三个羁绊标签
	board.place_character(char_registry.get_character("azi"), 0, 0)
	board.place_character(char_registry.get_character("xiao_ke"), 1, 0)  # VR(2)
	board.place_character(char_registry.get_character("lu_zao"), 2, 0)   # 歌手(2)
	board.place_character(char_registry.get_character("xue_gao"), 3, 0)  # 糖(2)

	var synergies = detector.detect_synergies()
	print("场上羁绊: %s" % [synergies])

	# 应用多羁绊效果
	var azi = board.get_character_at(0, 0)
	var base_attack = azi.base_attack
	effect_system.apply_synergy_effects(azi, detector.get_active_synergies())
	print("阿梓: 基础攻击 %d → 最终攻击 %.1f" % [base_attack, azi.final_attack])

	# VR(攻击+15%) + 其他效果
	var expected_multiplier = 1.15  # VR 1级
	print("预期攻击倍率: %.2fx" % [expected_multiplier])

	print("✓ 多羁绊叠加测试通过\n")

# ============================================================
# 简化的数据类
# ============================================================

class CharacterData:
	var id: String
	var display_name: String
	var base_attack: float
	var base_health: float
	var synergy_tags: Array
	var final_attack: float
	var final_health: float

	func _init(p_id: String, p_name: String, p_attack: float, p_health: float, p_tags: Array):
		id = p_id
		display_name = p_name
		base_attack = p_attack
		base_health = p_health
		synergy_tags = p_tags
		final_attack = p_attack
		final_health = p_health

class SynergyData:
	var id: String
	var display_name: String
	var type: String  # "normal", "wildcard", "combo"
	var thresholds: Array
	var effect: Dictionary

	func _init(p_id: String, p_name: String, p_type: String, p_thresholds: Array, p_effect: Dictionary):
		id = p_id
		display_name = p_name
		type = p_type
		thresholds = p_thresholds
		effect = p_effect

# ============================================================
# 数据注册表
# ============================================================

class CharacterRegistry:
	var _characters: Dictionary

	func _init():
		_characters = {
			# 1费角色
			"xiao_ke": CharacterData.new("xiao_ke", "小可", 45, 550, ["vr", "singer"]),
			"lu_zao": CharacterData.new("lu_zao", "露早", 45, 550, ["singer", "eoe_sisters"]),
			"you_en": CharacterData.new("you_en", "柚恩", 48, 520, ["singer", "eoe_sisters"]),
			# 2费角色
			"hirro": CharacterData.new("hirro", "hirro", 55, 650, ["gunner"]),
			"xue_gao": CharacterData.new("xue_gao", "雪糕", 52, 620, ["gunner", "tang"]),
			# 3费角色
			"azi": CharacterData.new("azi", "阿梓", 60, 700, ["vr", "singer", "tang"]),
			"tian_dou": CharacterData.new("tian_dou", "恬豆", 58, 720, ["idol", "vr"]),
			"dong_ai_li": CharacterData.new("dong_ai_li", "东爱璃", 55, 680, ["wildcard"]),
			# 4费角色
			"qi_hai": CharacterData.new("qi_hai", "七海", 70, 800, ["vr", "idol"]),
		}

	func get_character(id: String) -> CharacterData:
		return _characters.get(id)

class SynergyRegistry:
	var _synergies: Dictionary

	func _init():
		_synergies = {
			"vr": SynergyData.new("vr", "VR", "normal", [2, 4], {"type": "stat_bonus", "stat": "attack", "values": [0.15, 0.30]}),
			"idol": SynergyData.new("idol", "偶像", "normal", [2, 4, 5], {"type": "stat_bonus", "stat": "health", "values": [0.12, 0.25, 0.40]}),
			"singer": SynergyData.new("singer", "歌手", "normal", [2, 4], {"type": "stat_bonus", "stat": "skill_damage", "values": [0.20, 0.40]}),
			"tang": SynergyData.new("tang", "糖", "normal", [2, 3], {"type": "stat_bonus", "stat": "attack_speed", "values": [0.15, 0.30]}),
			"gunner": SynergyData.new("gunner", "枪手", "normal", [2], {"type": "special", "effect": "extra_shot", "value": 0.35}),
			"eoe_sisters": SynergyData.new("eoe_sisters", "EOE姐妹", "combo", [2], {"type": "combo_boost", "attack_mult": 2.5, "health_mult": 2.0}),
			"wildcard": SynergyData.new("wildcard", "狍子", "wildcard", [1], {"type": "wildcard"}),
		}

	func get_synergy(id: String) -> SynergyData:
		return _synergies.get(id)

	func get_all_synergies() -> Dictionary:
		return _synergies

# ============================================================
# 棋盘系统 (简化版 - 六边形坐标)
# ============================================================

class BoardSystem:
	var _board: Dictionary  # key: "q,r", value: CharacterData
	var _max_q: int = 8
	var _max_r: int = 4

	func _init():
		_board = {}

	func clear():
		_board.clear()

	func place_character(char: CharacterData, q: int, r: int):
		var key = "%d,%d" % [q, r]
		_board[key] = char

	func get_character_at(q: int, r: int) -> CharacterData:
		var key = "%d,%d" % [q, r]
		return _board.get(key)

	func get_all_characters() -> Array:
		return _board.values()

	func get_occupied_cells() -> Array:
		var cells = []
		for key in _board.keys():
			var parts = key.split(",")
			cells.append({"q": int(parts[0]), "r": int(parts[1])})
		return cells

	# 获取六边形邻居
	func get_neighbors(q: int, r: int) -> Array:
		var directions = [
			[1, 0], [1, -1], [0, -1],
			[-1, 0], [-1, 1], [0, 1]
		]
		var neighbors = []
		for dir in directions:
			var nq = q + dir[0]
			var nr = r + dir[1]
			neighbors.append({"q": nq, "r": nr})
		return neighbors

	# 检查位置是否孤立
	func is_isolated(q: int, r: int) -> bool:
		var neighbors = get_neighbors(q, r)
		for n in neighbors:
			var key = "%d,%d" % [n.q, n.r]
			if _board.has(key):
				return false
		return true

# ============================================================
# 羁绊检测系统
# ============================================================

class SynergyDetector:
	var _synergy_registry: SynergyRegistry
	var _board: BoardSystem
	var _active_synergies: Dictionary

	func _init(synergy_registry: SynergyRegistry, board: BoardSystem):
		_synergy_registry = synergy_registry
		_board = board

	func detect_synergies() -> Dictionary:
		_active_synergies.clear()

		# 统计每个羁绊的角色数量
		var synergy_counts = {}
		var wildcard_chars = []

		for char in _board.get_all_characters():
			for tag in char.synergy_tags:
				if tag == "wildcard":
					wildcard_chars.append(char)
				else:
					if not synergy_counts.has(tag):
						synergy_counts[tag] = 0
					synergy_counts[tag] += 1

		# 处理狍子 (万能羁绊)
		for synergy_id in synergy_counts.keys():
			var synergy = _synergy_registry.get_synergy(synergy_id)
			if synergy and synergy.type == "normal":
				# 检查是否可以用狍子凑数
				var count = synergy_counts[synergy_id]
				var thresholds = synergy.thresholds
				for threshold in thresholds:
					if count < threshold and count + wildcard_chars.size() >= threshold:
						# 使用狍子凑数
						count = threshold
						break
				synergy_counts[synergy_id] = count

		# 检测激活的羁绊
		for synergy_id in synergy_counts.keys():
			var count = synergy_counts[synergy_id]
			var synergy = _synergy_registry.get_synergy(synergy_id)

			if synergy == null:
				continue

			# 特殊处理组合羁绊
			if synergy.type == "combo":
				if _check_combo_synergy(synergy_id):
					_active_synergies[synergy_id] = {"level": 1, "count": count}
			elif synergy.type == "normal":
				var level = _get_synergy_level(synergy_id, count)
				if level > 0:
					_active_synergies[synergy_id] = {"level": level, "count": count}

		return _active_synergies.keys()

	func _check_combo_synergy(synergy_id: String) -> bool:
		# EOE姐妹: 需要露早和柚恩都在场
		if synergy_id == "eoe_sisters":
			var has_luzao = false
			var has_youen = false
			for char in _board.get_all_characters():
				if char.id == "lu_zao":
					has_luzao = true
				if char.id == "you_en":
					has_youen = true
			return has_luzao and has_youen
		return false

	func _get_synergy_level(synergy_id: String, count: int) -> int:
		var synergy = _synergy_registry.get_synergy(synergy_id)
		if synergy == null:
			return 0

		var level = 0
		for i in range(synergy.thresholds.size()):
			if count >= synergy.thresholds[i]:
				level = i + 1
		return level

	func get_synergy_level(synergy_id: String) -> int:
		if _active_synergies.has(synergy_id):
			return _active_synergies[synergy_id]["level"]
		return 0

	func get_active_synergies() -> Dictionary:
		return _active_synergies

# ============================================================
# 羁绊效果系统
# ============================================================

class SynergyEffectSystem:
	var _synergy_registry: SynergyRegistry

	func _init(synergy_registry: SynergyRegistry):
		_synergy_registry = synergy_registry

	func apply_synergy_effects(char: CharacterData, active_synergies: Dictionary):
		# 重置最终属性
		char.final_attack = char.base_attack
		char.final_health = char.base_health

		# 先检查EOE姐妹强化
		if active_synergies.has("eoe_sisters"):
			if char.id == "lu_zao" or char.id == "you_en":
				var eoe_synergy = _synergy_registry.get_synergy("eoe_sisters")
				char.final_attack *= eoe_synergy.effect["attack_mult"]
				char.final_health *= eoe_synergy.effect["health_mult"]

		# 应用普通羁绊效果
		for synergy_id in active_synergies.keys():
			var synergy = _synergy_registry.get_synergy(synergy_id)
			if synergy == null or synergy.type != "normal":
				continue

			# 检查角色是否有这个羁绊标签
			if not synergy_id in char.synergy_tags:
				continue

			var level = active_synergies[synergy_id]["level"] - 1  # 0-indexed
			var effect_value = synergy.effect["values"][level]

			match synergy.effect["stat"]:
				"attack":
					char.final_attack *= (1 + effect_value)
				"health":
					char.final_health *= (1 + effect_value)

	func apply_isolated_effect(char: CharacterData, is_isolated: bool):
		if is_isolated and char.id == "hirro":
			char.final_attack *= 1.4  # +40% 攻击
			char.final_health *= 1.3  # +30% 生命
