extends Node2D

@export var damage_amout: int = 1;

@onready var area_2D: Area2D = $Area2D;

func deal_damage():
	var bodies = area_2D.get_overlapping_bodies();
	var a = RandomNumberGenerator.new();
	for body in bodies:
		if body.is_in_group("enemies"):
			var enemy: Enemy = body;
			enemy.damage(damage_amout * a.randf());
		elif body.is_in_group("estruturas"):
			#Casas dos goblins (o corpo de colisão é filho da casa)
			body.owner.damage(damage_amout * a.randf());
