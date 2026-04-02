# Game.gd
# 游戏主场景脚本
# 初始化系统、管理场景生命周期和阶段转换
extends Node2D

# PRODUCTION CODE - V-Tacit Main Game

## 棋盘系统
@onready var board_system: BoardSystem = $BoardSystem

## 棋盘渲染器
@onready var board_renderer: BoardRenderer = $BoardRenderer

## 角色渲染器
@onready var character_renderer: CharacterRenderer = $CharacterRenderer

## 格子显示系统
@onready var cell_display: CellDisplaySystem = $CellDisplaySystem

## 卡池管理器
@onready var card_pool: CardPoolManager = $CardPoolManager

## 商店系统
@onready var shop_system: ShopSystem = $ShopSystem

## 拖放控制器
@onready var drag_controller: DragDropController = $DragDropController

## 羁绊检测系统
@onready var synergy_detection: SynergyDetectionSystem = $SynergyDetectionSystem

## 羁绊效果系统
@onready var synergy_effect: SynergyEffectSystem = $SynergyEffectSystem

## 属性计算系统
@onready var attribute_calc: AttributeCalculationSystem = $AttributeCalculationSystem

## 战斗系统
@onready var battle_system: BattleSystem = $BattleSystem

## 升星系统
@onready var star_upgrade: StarUpgradeSystem = $StarUpgradeSystem

## 战斗时间线系统
@onready var battle_timeline: BattleTimelineSystem = $BattleTimelineSystem

## 战斗AI系统
@onready var battle_ai: BattleAISystem = $BattleAISystem

## 战斗动画系统
@onready var battle_animation: BattleAnimationSystem = $BattleAnimationSystem

## 战斗日志系统
@onready var battle_log: BattleLogSystem = $BattleLogSystem

## 商店面板
@onready var shop_panel: ShopPanel = $UI/ShopPanel

## 战斗结果面板
@onready var battle_result_panel: BattleResultPanel = $UI/BattleResultPanel

## 羁绊面板
@onready var synergy_panel: SynergyPanel = $UI/SynergyPanel

## 对手选择面板
@onready var enemy_select_panel: EnemySelectPanel = $UI/EnemySelectPanel

## 战斗日志面板
@onready var battle_log_panel: BattleLogPanel = $UI/BattleLogPanel

## 战斗控制面板
@onready var battle_control_panel: BattleControlPanel = $UI/BattleControlPanel

## 战斗按钮
@onready var battle_button: Button = $UI/ShopPanel/ButtonContainer/BattleButton


func _ready() -> void:
	# 初始化注册表
	_initialize_registries()

	# 初始化卡池（必须在注册表之后）
	_initialize_card_pool()

	# 连接系统
	_connect_systems()

	# 初始化商店（必须在卡池之后）
	_initialize_shop()

	# 连接UI事件
	_connect_ui_events()

	# 应用苹果风格UI
	_apply_apple_style()

	# 进入商店阶段
	_start_shop_phase()

	print("V-Tacit initialized")


func _apply_apple_style() -> void:
	# 战斗按钮苹果风格
	if battle_button:
		var normal_style := StyleBoxFlat.new()
		normal_style.bg_color = Color(0.85, 0.25, 0.25, 0.9)  # 红色
		normal_style.set_corner_radius_all(6)
		battle_button.add_theme_stylebox_override("normal", normal_style)
		battle_button.add_theme_color_override("font_color", Color.WHITE)
		battle_button.add_theme_font_size_override("font_size", 13)

		var hover_style := StyleBoxFlat.new()
		hover_style.bg_color = Color(0.9, 0.35, 0.35, 0.95)
		hover_style.set_corner_radius_all(6)
		battle_button.add_theme_stylebox_override("hover", hover_style)


func _initialize_registries() -> void:
	CharacterRegistry.initialize()
	SynergyRegistry.initialize()

	# 验证数据
	if not CharacterRegistry.validate_all():
		push_error("Character data validation failed")
	if not SynergyRegistry.validate_all():
		push_error("Synergy data validation failed")

	print("Loaded %d characters, %d synergies" % [
		CharacterRegistry.get_character_count(),
		SynergyRegistry.get_synergy_count()
	])


func _initialize_card_pool() -> void:
	if card_pool:
		card_pool.initialize_pool()
		print("Card pool initialized with %d cards" % card_pool.get_total_count())


func _connect_systems() -> void:
	# 连接渲染器到棋盘系统
	if board_renderer and board_system:
		board_renderer.board_system = board_system

	# 连接角色渲染器
	if character_renderer:
		character_renderer.board_system = board_system
		character_renderer.synergy_effect = synergy_effect
		character_renderer.drag_controller = drag_controller

	# 连接格子显示系统
	if cell_display:
		cell_display.board_renderer = board_renderer
		cell_display.board_system = board_system

	# 连接拖放控制器
	if drag_controller:
		drag_controller.board_system = board_system
		drag_controller.cell_display = cell_display
		# 连接拖动预览信号
		if character_renderer:
			drag_controller.preview_updated.connect(character_renderer.set_drag_preview)

	# 连接商店系统
	if shop_system and card_pool:
		shop_system.card_pool = card_pool

	# 连接羁绊检测系统
	if synergy_detection:
		synergy_detection.board_system = board_system

	# 连接羁绊效果系统
	if synergy_effect:
		synergy_effect.detection_system = synergy_detection
		synergy_effect.board_system = board_system

	# 连接属性计算系统
	if attribute_calc:
		attribute_calc.synergy_effect_system = synergy_effect
		attribute_calc.board_system = board_system

	# 连接战斗系统
	if battle_system:
		battle_system.attribute_calc = attribute_calc
		battle_system.synergy_effect = synergy_effect
		battle_system.synergy_detection = synergy_detection
		battle_system.board_system = board_system

	# 连接升星系统
	if star_upgrade:
		star_upgrade.board_system = board_system
		# 连接升星信号
		star_upgrade.character_upgraded.connect(_on_character_upgraded)

	# 连接战斗时间线系统
	if battle_timeline:
		battle_timeline.board_system = board_system
		battle_timeline.battle_system = battle_system

	# 连接战斗AI系统
	if battle_ai:
		battle_ai.board_system = board_system
		if battle_timeline:
			battle_timeline.ai_system = battle_ai

	# 连接战斗动画系统
	if battle_animation:
		battle_animation.board_system = board_system
		battle_animation.character_renderer = character_renderer
		if battle_timeline:
			battle_timeline.animation_system = battle_animation

	# 连接战斗日志系统
	if battle_log:
		if battle_timeline:
			battle_timeline.battle_ended.connect(_on_auto_battle_ended)
		if battle_log_panel:
			battle_log_panel.log_system = battle_log

	# 连接战斗控制面板
	if battle_control_panel:
		battle_control_panel.speed_changed.connect(_on_battle_speed_changed)
		battle_control_panel.skip_requested.connect(_on_battle_skip_requested)


func _on_character_upgraded(instance: CharacterInstance, old_star: int, new_star: int) -> void:
	# 更新羁绊和属性
	if attribute_calc:
		attribute_calc.calculate_all_attributes()

	if synergy_panel:
		synergy_panel.update_display()

	# 更新渲染
	if character_renderer:
		character_renderer.request_redraw()

	print("角色 %s 升星: %d -> %d" % [instance.character_id, old_star, new_star])



func _initialize_shop() -> void:
	# 连接商店面板
	if shop_panel:
		shop_panel.shop_system = shop_system
		shop_panel.drag_controller = drag_controller

		# 连接拖放结束事件
		if drag_controller:
			drag_controller.drag_ended.connect(_on_drag_ended)

	# 初始刷新商店
	if shop_system:
		shop_system.refresh_shop()


func _connect_ui_events() -> void:
	# 战斗按钮
	if battle_button:
		battle_button.pressed.connect(_on_battle_button_pressed)

	# 战斗结果面板
	if battle_result_panel:
		battle_result_panel.continue_pressed.connect(_on_continue_pressed)
		battle_result_panel.reset_pressed.connect(_on_reset_pressed)

	# 羁绊面板
	if synergy_panel:
		synergy_panel.detection_system = synergy_detection

	# 对手选择面板
	if enemy_select_panel:
		enemy_select_panel.battle_system = battle_system
		enemy_select_panel.enemy_selected.connect(_on_enemy_selected)


#region 阶段管理

func _start_shop_phase() -> void:
	GameState.set_phase(GameState.Phase.SHOP)

	# 显示商店UI
	if shop_panel:
		shop_panel.show()

	if battle_button:
		battle_button.show()

	if battle_result_panel:
		battle_result_panel.hide()

	# 显示对手选择面板
	if enemy_select_panel:
		enemy_select_panel.show_panel()

	# 更新羁绊面板
	if synergy_panel:
		synergy_panel.update_display()


func _start_battle_phase() -> void:
	GameState.set_phase(GameState.Phase.BATTLE)

	# 隐藏商店UI
	if shop_panel:
		shop_panel.hide()

	if battle_button:
		battle_button.hide()

	# 隐藏对手选择面板
	if enemy_select_panel:
		enemy_select_panel.hide_panel()

	# 显示战斗日志面板
	if battle_log_panel:
		battle_log_panel.show_panel()

	# 显示战斗控制面板
	if battle_control_panel:
		battle_control_panel.show_panel()
		battle_control_panel.reset_speed()

	# 计算属性
	if attribute_calc:
		attribute_calc.calculate_all_attributes()

	# 执行战斗（使用自走战斗系统）
	if battle_timeline and battle_system:
		# 生成敌方队伍
		var _enemy_instances := battle_system.execute_battle()
		var enemy_team := battle_system.get_enemy_team()
		var player_team := board_system.get_all_characters()

		# 清空日志
		if battle_log:
			battle_log.clear_logs()

		# 开始自走战斗
		battle_timeline.start_battle(player_team, enemy_team)
	else:
		# 回退到简单战斗计算
		if battle_system:
			var result := battle_system.execute_battle()
			if result.has("error"):
				push_warning("Battle failed: %s" % result.error)
				_start_shop_phase()
			else:
				_start_result_phase(result)


func _start_result_phase(result: Dictionary) -> void:
	GameState.set_phase(GameState.Phase.RESULT)

	# 显示战斗结果
	if battle_result_panel:
		battle_result_panel.show_result(result)

	# 增加回合
	GameState.increment_round()


func _reset_game() -> void:
	# 清空棋盘
	if board_system:
		board_system.clear_board()

	# 重置卡池
	if card_pool:
		card_pool.reset_pool()

	# 重置游戏状态
	GameState.reset_game()

	# 重置商店（在 GameState.reset_game() 之后）
	if shop_system:
		shop_system.clear_shop()
		shop_system.refresh_shop()

	# 清空战斗结果
	if battle_result_panel:
		battle_result_panel.clear_result()

	# 更新商店显示
	if shop_panel:
		shop_panel.update_display()

	# 更新羁绊面板
	if synergy_panel:
		synergy_panel.update_display()

	# 回到商店阶段
	_start_shop_phase()

	print("Game reset")


#endregion


#region 信号处理

func _on_drag_ended(success: bool, position: Vector2i) -> void:
	if shop_panel:
		shop_panel.update_display()

	# 如果放置成功，更新羁绊和属性
	if success:
		# 检查升星
		var placed_instance := board_system.get_character_at(position.x, position.y)
		if placed_instance and star_upgrade:
			star_upgrade.check_and_upgrade(placed_instance, position.x, position.y)

		if attribute_calc:
			attribute_calc.calculate_all_attributes()

		if synergy_panel:
			synergy_panel.update_display()

		_print_synergy_status()


func _on_enemy_selected(_index: int) -> void:
	# 对手选择后更新显示
	if enemy_select_panel:
		enemy_select_panel.refresh_buttons()
	print("Selected enemy: %s" % battle_system.get_selected_enemy()["name"])


func _on_auto_battle_ended(winner: String) -> void:
	# 自走战斗结束
	print("Auto-battle ended: %s wins" % winner)

	# 构建战斗结果
	var player_wins := winner == "player"
	var result := {
		"player_wins": player_wins,
		"win_rate": battle_system.get_last_battle_result().get("win_rate", 0.5),
		"player_power": battle_system.get_last_battle_result().get("player_power", 0),
		"enemy_power": battle_system.get_last_battle_result().get("enemy_power", 0),
		"turns": battle_timeline.current_turn if battle_timeline else 0
	}

	# 显示结果
	_start_result_phase(result)


func _on_battle_button_pressed() -> void:
	# 检查棋盘是否为空
	if board_system and board_system.get_character_count() == 0:
		print("Please place at least one character")
		return

	_start_battle_phase()


func _on_continue_pressed() -> void:
	# 隐藏战斗结果
	if battle_result_panel:
		battle_result_panel.hide_result()

	# 隐藏战斗日志面板
	if battle_log_panel:
		battle_log_panel.hide_panel()

	# 隐藏战斗控制面板
	if battle_control_panel:
		battle_control_panel.hide_panel()

	# 清空敌方棋盘
	if battle_system:
		battle_system.clear_enemy_team()

	# 更新角色渲染器
	if character_renderer:
		character_renderer.request_redraw()

	# 重新刷新商店
	if shop_system:
		shop_system.refresh_shop()

	# 更新商店显示
	if shop_panel:
		shop_panel.update_display()

	# 增加回合后继续
	_start_shop_phase()


func _on_reset_pressed() -> void:
	# 隐藏战斗日志面板
	if battle_log_panel:
		battle_log_panel.hide_panel()

	# 隐藏战斗控制面板
	if battle_control_panel:
		battle_control_panel.hide_panel()

	# 清空敌方棋盘
	if battle_system:
		battle_system.clear_enemy_team()

	_reset_game()


func _print_synergy_status() -> void:
	if synergy_detection == null:
		return

	var active := synergy_detection.get_active_synergies()
	if active.is_empty():
		print("No active synergies")
	else:
		print("Active synergies: %s" % str(active.keys()))


func _on_battle_speed_changed(speed: float) -> void:
	if battle_timeline:
		battle_timeline.set_speed(speed)
	if battle_animation:
		battle_animation.set_animation_speed(speed)
	print("Battle speed: %dx" % int(speed))


func _on_battle_skip_requested() -> void:
	if battle_timeline and battle_timeline.is_battle_in_progress():
		battle_timeline.skip_battle()
		print("Battle skipped")


#endregion
