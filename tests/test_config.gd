# Test Configuration
# Run tests with: godot --headless -s addons/gut/gut_cmdln.gd

extends GutTest


func before_all() -> void:
	# Initialize registries for all tests
	CharacterRegistry.initialize()
	SynergyRegistry.initialize()


func before_each() -> void:
	# Reset global state between tests to prevent cross-test contamination
	if GameState:
		GameState.reset_game()
