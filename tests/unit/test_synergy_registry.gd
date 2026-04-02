# test_synergy_registry.gd
# Unit tests for SynergyRegistry

extends GutTest

var _registry: SynergyRegistry


func before_each() -> void:
	_registry = SynergyRegistry.new()
	_registry.initialize()


func after_each() -> void:
	_registry = null


func test_initialization() -> void:
	assert_true(_registry._is_initialized, "Registry should be initialized")
	assert_gt(_registry.get_synergy_count(), 0, "Should have loaded synergies")


func test_get_synergy() -> void:
	var synergy := _registry.get_synergy("VR")
	assert_not_null(synergy, "Should find VR synergy")
	assert_eq(synergy.display_name, "VR", "Display name should match")
	assert_eq(synergy.type, "normal", "Type should be normal")


func test_get_nonexistent_synergy() -> void:
	var synergy := _registry.get_synergy("nonexistent")
	assert_null(synergy, "Should return null for nonexistent synergy")


func test_get_thresholds() -> void:
	var thresholds := _registry.get_thresholds("VR")
	assert_eq(thresholds.size(), 2, "VR should have 2 thresholds")
	assert_eq(thresholds[0], 2, "First threshold should be 2")
	assert_eq(thresholds[1], 4, "Second threshold should be 4")


func test_get_by_type() -> void:
	var normal_synergies := _registry.get_by_type("normal")
	assert_gt(normal_synergies.size(), 0, "Should find normal synergies")

	for synergy in normal_synergies:
		assert_eq(synergy.type, "normal", "All results should be normal type")


func test_get_wildcard_synergies() -> void:
	var wildcards := _registry.get_wildcard_synergies()
	assert_gt(wildcards.size(), 0, "Should find wildcard synergies")

	for synergy in wildcards:
		assert_true(synergy.is_wildcard(), "All results should be wildcard")


func test_get_combo_synergies() -> void:
	var combos := _registry.get_combo_synergies()
	assert_gt(combos.size(), 0, "Should find combo synergies")

	for synergy in combos:
		assert_true(synergy.is_combo(), "All results should be combo")


func test_get_hidden_synergies() -> void:
	var hidden := _registry.get_hidden_synergies()
	assert_gt(hidden.size(), 0, "Should find hidden synergies")

	for synergy in hidden:
		assert_true(synergy.is_hidden(), "All results should be hidden")


func test_synergy_level_calculation() -> void:
	var synergy := _registry.get_synergy("VR")

	assert_eq(synergy.get_level_for_count(1), 0, "1 character should not activate")
	assert_eq(synergy.get_level_for_count(2), 1, "2 characters should be level 1")
	assert_eq(synergy.get_level_for_count(4), 2, "4 characters should be level 2")


func test_synergy_effect_id() -> void:
	var synergy := _registry.get_synergy("VR")

	assert_eq(synergy.get_effect_id_for_level(1), "vr_attack_1", "Level 1 effect should match")
	assert_eq(synergy.get_effect_id_for_level(2), "vr_attack_2", "Level 2 effect should match")


func test_validate_all() -> void:
	assert_true(_registry.validate_all(), "All synergy data should be valid")
