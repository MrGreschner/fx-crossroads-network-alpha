extends "res://scripts/game.gd"
var test_target:=Vector2(1100,1050)
func aimed_point(_max_range:float)->Vector2:return test_target
func aim_direction()->Vector2:return (test_target-position_in_world).normalized()
