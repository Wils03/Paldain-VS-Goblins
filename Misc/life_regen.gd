extends Node2D

@export var regen_amout: float = 10;

#@onready var area_2D: Area2D = $Area2D;


func _ready():
	$Area2D.body_entered.connect(on_body_entered);
	
	
func on_body_entered(body: Node2D):
	#Ainda voando (animação de drop): não pode ser coletado
	if has_meta(SpawnUtils.DROP_IN_AIR): return
	if body.is_in_group("player"):
		var player: Player = body
		player.heal(regen_amout);
		Sfx.play("meat_pickup");
		queue_free();
