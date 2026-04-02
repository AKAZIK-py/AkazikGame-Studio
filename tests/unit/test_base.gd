# test_base.gd
# Base class for all unit tests
# Provides common setup/teardown and global state reset

extends GutTest


func before_each() -> void:
	# Reset global state between tests to prevent cross-test contamination
	GameState.reset_game()


func after_each() -> void:
	# Ensure clean state after test completes
	GameState.reset_game()
