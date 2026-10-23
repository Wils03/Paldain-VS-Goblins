extends Node

var enemy: Enemy;

func _ready():
	enemy = get_parent()
	enemy.health = 20;
