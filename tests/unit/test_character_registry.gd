# test_character_registry.gd
# Unit tests for CharacterRegistry

extends GutTest

var _registry: CharacterRegistry


func before_each() -> void:
	_registry = CharacterRegistry.new()
	_registry.initialize()


func after_each() -> void:
	_registry = null


func test_initialization() -> void:
	assert_true(_registry._is_initialized, "Registry should be initialized")
	assert_gt(_registry.get_character_count(), 0, "Should have loaded characters")


func test_get_character() -> void:
	var char_data := _registry.get_character("a_zi")
	assert_not_null(char_data, "Should find 阿梓")
	assert_eq(char_data.display_name, "阿梓", "Display name should match")
	assert_eq(char_data.rarity, 3, "Rarity should be 3")


func test_get_nonexistent_character() -> void:
	var char_data := _registry.get_character("nonexistent")
	assert_null(char_data, "Should return null for nonexistent character")


func test_get_by_synergy_tag() -> void:
	var vr_chars := _registry.get_by_synergy_tag("VR")
	assert_gt(vr_chars.size(), 0, "Should find VR characters")

	for char_data in vr_chars:
		assert_true("VR" in char_data.synergy_tags, "All results should have VR tag")


func test_get_by_rarity() -> void:
	var tier1_chars := _registry.get_by_rarity(1)
	assert_gt(tier1_chars.size(), 0, "Should find tier 1 characters")

	for char_data in tier1_chars:
		assert_eq(char_data.rarity, 1, "All results should be rarity 1")


func test_get_by_role() -> void:
	var output_chars := _registry.get_by_role("output")
	assert_gt(output_chars.size(), 0, "Should find output role characters")

	for char_data in output_chars:
		assert_eq(char_data.role, "output", "All results should have output role")


func test_get_all_synergy_tags() -> void:
	var tags := _registry.get_all_synergy_tags()
	assert_gt(tags.size(), 0, "Should have synergy tags")
	assert_true("VR" in tags, "Should have VR tag")
	assert_true("idol" in tags, "Should have idol tag")


func test_rarity_distribution() -> void:
	var dist := _registry.get_rarity_distribution()

	assert_gt(dist.get(1, 0), 0, "Should have tier 1 characters")
	assert_gt(dist.get(5, 0), 0, "Should have tier 5 characters")


func test_has_character() -> void:
	assert_true(_registry.has_character("a_zi"), "Should have 阿梓")
	assert_false(_registry.has_character("nonexistent"), "Should not have nonexistent")


func test_validate_all() -> void:
	assert_true(_registry.validate_all(), "All character data should be valid")
