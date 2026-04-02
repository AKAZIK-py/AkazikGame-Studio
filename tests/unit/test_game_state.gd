# test_game_state.gd
# Unit tests for GameState

extends GutTest


func before_all() -> void:
	CharacterRegistry.initialize()


func before_each() -> void:
	GameState.reset_game()


func test_initial_state() -> void:
	assert_eq(GameState.current_phase, GameState.Phase.SHOP, "Should start in SHOP phase")
	assert_eq(GameState.get_board_count(), 0, "Board should be empty")


func test_phase_change() -> void:
	GameState.set_phase(GameState.Phase.BATTLE)
	assert_eq(GameState.current_phase, GameState.Phase.BATTLE, "Phase should change to BATTLE")

	GameState.set_phase(GameState.Phase.RESULT)
	assert_eq(GameState.current_phase, GameState.Phase.RESULT, "Phase should change to RESULT")


func test_place_character() -> void:
	var char_data := CharacterRegistry.get_character("a_zi")
	assert_not_null(char_data, "Should have 阿梓 data")

	var instance := GameState.place_character(char_data, 0, 0)
	assert_not_null(instance, "Should place character")
	assert_eq(GameState.get_board_count(), 1, "Board should have 1 character")
	assert_eq(instance.character_id, "a_zi", "Character ID should match")


func test_remove_character() -> void:
	var char_data := CharacterRegistry.get_character("a_zi")
	GameState.place_character(char_data, 0, 0)

	var removed := GameState.remove_character(0, 0)
	assert_not_null(removed, "Should remove character")
	assert_eq(GameState.get_board_count(), 0, "Board should be empty")


func test_move_character() -> void:
	var char_data := CharacterRegistry.get_character("a_zi")
	GameState.place_character(char_data, 0, 0)

	var success := GameState.move_character(0, 0, 1, 1)
	assert_true(success, "Move should succeed")
	assert_not_null(GameState.get_character_at(1, 1), "Character should be at new position")
	assert_null(GameState.get_character_at(0, 0), "Old position should be empty")


func test_move_to_occupied() -> void:
	var char_data1 := CharacterRegistry.get_character("a_zi")
	var char_data2 := CharacterRegistry.get_character("xiao_ke")
	GameState.place_character(char_data1, 0, 0)
	GameState.place_character(char_data2, 1, 1)

	var success := GameState.move_character(0, 0, 1, 1)
	assert_false(success, "Move to occupied cell should fail")
	assert_not_null(GameState.get_character_at(0, 0), "Original position should still have character")


func test_reset_game() -> void:
	var char_data := CharacterRegistry.get_character("a_zi")
	GameState.place_character(char_data, 0, 0)
	GameState.set_phase(GameState.Phase.BATTLE)
	GameState.increment_round()

	GameState.reset_game()

	assert_eq(GameState.current_phase, GameState.Phase.SHOP, "Should reset to SHOP phase")
	assert_eq(GameState.get_board_count(), 0, "Board should be empty")
	assert_eq(GameState.get_total_rounds(), 0, "Rounds should be reset")


func test_shop_cards() -> void:
	var cards: Array[CharacterData] = []
	cards.append(CharacterRegistry.get_character("a_zi"))
	cards.append(CharacterRegistry.get_character("xiao_ke"))

	GameState.set_shop_cards(cards)

	var shop_cards := GameState.get_shop_cards()
	assert_eq(shop_cards.size(), 2, "Should have 2 shop cards")


func test_refresh_count() -> void:
	assert_eq(GameState.get_refresh_count(), 0, "Initial refresh count should be 0")

	GameState.increment_refresh_count()
	assert_eq(GameState.get_refresh_count(), 1, "Should increment refresh count")

	GameState.reset_refresh_count()
	assert_eq(GameState.get_refresh_count(), 0, "Should reset refresh count")
