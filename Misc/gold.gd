extends Node2D

#Quanto de ouro o item vale (saco = 5, moeda = 1)
@export var gold_amout: float = 5;

#@onready var area_2D: Area2D = $Area2D;


func _ready():
	$Area2D.body_entered.connect(on_body_entered);
	
	
func on_body_entered(body: Node2D):
	#Ainda voando (animação de drop): não pode ser coletado
	if has_meta(SpawnUtils.DROP_IN_AIR): return
	if body.is_in_group("player"):
		var player: Player = body
		player.obtain_gold(gold_amout);
		player.gold_colected.emit(int(gold_amout));
		Sfx.play("gold_pickup");
		queue_free();
