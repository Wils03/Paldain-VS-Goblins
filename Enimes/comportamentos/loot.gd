extends Node

@export var loot: Array[PackedScene];
@export var drop_chances: Array[float];

@onready var node: CharacterBody2D = $".."

func loot_create(position) -> AnimatedSprite2D:
	var drop = get_random_drop_item().instantiate();
	#Garante que o item caia num lugar que o player consegue alcançar
	#(nunca na água, na borda do mapa ou dentro de árvores/casas)
	drop.position = SpawnUtils.ajustar_drop(node, position + Vector2(40,0), pes_do_inimigo(position));
	return drop;

#Ponto onde o inimigo estava pisando: com certeza é andável
func pes_do_inimigo(position: Vector2) -> Vector2:
	var collision: Node2D = node.get_node_or_null("CollisionShape2D");
	var feet = collision.global_position if collision else position;
	return feet - SpawnUtils.PICKUP_OFFSET;

func get_random_drop_item() -> PackedScene:
	if loot.size() == 1:
		return loot[0];
	
	var max_chance: float = 0.0
	for drop_chance in drop_chances:
		max_chance =+ drop_chance
	#jogar dado
	var random_value = randf() * max_chance;
	#girar rolet
	var needle: float = 0;
	for i in loot.size():
		var drop_item = loot[i]
		var drop_chance = drop_chances[i] if i < drop_chances.size() else 1;
		if random_value <= drop_chance + needle:
			return drop_item;
		needle += drop_chance
	return loot[0]
