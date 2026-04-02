# test_shop_system.gd
# Unit tests for ShopSystem

extends GutTest

var _shop: ShopSystem
var _pool: CardPoolManager


func before_all() -> void:
	CharacterRegistry.initialize()


func before_each() -> void:
	_pool = CardPoolManager.new()
	_pool.initialize_pool()

	_shop = ShopSystem.new()
	_shop.card_pool = _pool
	add_child(_shop)
	add_child(_pool)

	_shop.initialize()


func after_each() -> void:
	if _shop:
		_shop.queue_free()
	if _pool:
		_pool.queue_free()
	_shop = null
	_pool = null


func test_initialization() -> void:
	assert_eq(_shop.slot_count, 5, "Should have 5 slots")


func test_refresh_shop() -> void:
	_shop.refresh_shop()

	var cards := _shop.get_shop_cards()
	assert_eq(cards.size(), 5, "Should have 5 cards after refresh")


func test_select_character() -> void:
	_shop.refresh_shop()

	# Find a non-empty slot
	for i in range(_shop.slot_count):
		if not _shop.is_slot_empty(i):
			var card := _shop.select_character(i)
			assert_not_null(card, "Should select character")
			assert_true(_shop.is_slot_empty(i), "Slot should be empty after selection")
			return

	assert_true(false, "Should have found a non-empty slot")


func test_select_empty_slot() -> void:
	var card := _shop.select_character(0)
	assert_null(card, "Should return null for empty slot")


func test_get_filled_slot_count() -> void:
	_shop.refresh_shop()
	assert_eq(_shop.get_filled_slot_count(), 5, "Should have 5 filled slots")


func test_clear_shop() -> void:
	_shop.refresh_shop()
	_shop.clear_shop()

	assert_eq(_shop.get_filled_slot_count(), 0, "Should have 0 filled slots after clear")


func test_refresh_count() -> void:
	_shop.refresh_shop()
	_shop.refresh_shop()
	_shop.refresh_shop()

	assert_eq(_shop.get_refresh_count(), 3, "Should have refreshed 3 times")


func test_shop_signal() -> void:
	var signal_received := false
	var received_cards: Array = []

	_shop.shop_refreshed.connect(func(cards: Array):
		signal_received = true
		received_cards = cards
	)

	_shop.refresh_shop()

	assert_true(signal_received, "Should emit shop_refreshed signal")
	assert_eq(received_cards.size(), 5, "Should receive 5 cards")
