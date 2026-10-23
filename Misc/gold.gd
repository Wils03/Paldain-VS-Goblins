extends Node2D

@export var gold_amout: float = 10;

#@onready var area_2D: Area2D = $Area2D;


func _ready():
	$Area2D.body_entered.connect(on_body_entered);
	
	
func on_body_entered(body: Node2D):
	if body.is_in_group("player"):
		var player: Player = body
		player.obtain_gold(gold_amout);
		player.gold_colected.emit(gold_amout);
		Sfx.play("gold_pickup");
		queue_free();
