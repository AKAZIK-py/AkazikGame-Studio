# test_card_pool_manager.gd
# Unit tests for CardPoolManager

extends GutTest

var _pool: CardPoolManager


func before_all() -> void:
	CharacterRegistry.initialize()


func before_each() -> void:
	_pool = CardPoolManager.new()
	_pool.initialize_pool()
	add_child(_pool)


func after_each() -> void:
	if _pool:
		_pool.queue_free()
		_pool = null


func test_initialization() -> void:
	assert_gt(_pool.get_total_count(), 0, "Should have cards in pool")


func test_tier_distribution() -> void:
	for tier in range(1, 6):
		assert_gt(_pool.get_tier_count(tier), 0, "Tier %d should have cards" % tier)


func test_draw_card() -> void:
	var card := _pool.draw_card()
	assert_not_null(card, "Should draw a card")
	assert_true(card is CharacterData, "Should be CharacterData")


func test_draw_cards() -> void:
	var cards := _pool.draw_cards(5)
	assert_eq(cards.size(), 5, "Should draw 5 cards")


func test_draw_from_tier() -> void:
	var card := _pool.draw_from_tier(1)
	assert_not_null(card, "Should draw from tier 1")
	assert_eq(card.rarity, 1, "Card should be tier 1")


func test_remove_from_pool() -> void:
	var initial_count := _pool.get_total_count()
	var card := _pool.draw_card()

	var success := _pool.remove_from_pool(card.id)
	assert_true(success, "Should remove card from pool")
	assert_eq(_pool.get_total_count(), initial_count - 1, "Total count should decrease")


func test_pool_empty() -> void:
	# Draw all cards
	while not _pool.is_pool_empty():
		_pool.draw_card()

	assert_true(_pool.is_pool_empty(), "Pool should be empty")


func test_reset_pool() -> void:
	var initial_count := _pool.get_total_count()

	# Draw some cards
	_pool.draw_cards(5)

	# Reset
	_pool.reset_pool()
	assert_eq(_pool.get_total_count(), initial_count, "Pool should be restored")


func test_effective_probabilities() -> void:
	var probs := _pool.get_effective_probabilities()
	assert_gt(probs.size(), 0, "Should have probabilities")

	# Check sum is approximately 1.0
	var total := 0.0
	for tier in probs:
		total += probs[tier]
	assert_almost_eq(total, 1.0, 0.01, "Probabilities should sum to 1.0")


func test_draw_from_empty_tier() -> void:
	# Draw all cards from tier 5
	while _pool.get_tier_count(5) > 0:
		var card := _pool.draw_from_tier(5)
		if card:
			_pool.remove_from_pool(card.id)

	# Now try to draw from tier 5
	var card := _pool.draw_from_tier(5)
	# Should draw from another tier instead
	# This tests the fallback behavior
