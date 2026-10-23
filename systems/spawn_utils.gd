class_name SpawnUtils
extends RefCounted

#Regras de spawn compartilhadas pelo MobSpawner e pelas casas dos goblins

#Camadas "Mundo" (1) e "Limites" (4)
const BLOCKING_MASK = 0b1001;
#Camada do TileMap onde fica o chão andável
const GROUND_LAYER = 0;
#Raio usado quando a criatura não tem CollisionShape2D
const FALLBACK_RADIUS = 24.0;

#Verifica se a criatura cabe no ponto: tem chão e não encosta em parede/água
static func ponto_valido(world_node: Node2D, point: Vector2, creature: Node2D, solo: TileMap = null) -> bool:
	var parameters = PhysicsShapeQueryParameters2D.new();
	parameters.collision_mask = BLOCKING_MASK;

	#Usa o formato de colisão da própria criatura (fica nos pés, não na origem)
	var collision: CollisionShape2D = creature.get_node_or_null("CollisionShape2D");
	if collision and collision.shape:
		parameters.shape = collision.shape;
		parameters.transform = Transform2D(0.0, point) * collision.transform;
		parameters.margin = 6.0;
	else:
		var circle = CircleShape2D.new();
		circle.radius = FALLBACK_RADIUS;
		parameters.shape = circle;
		parameters.transform = Transform2D(0.0, point);

	#O chão é checado nos pés (centro da colisão)
	if not tem_chao(parameters.transform.origin, solo): return false
	var result: Array = world_node.get_world_2d().direct_space_state.intersect_shape(parameters, 1);
	return result.is_empty();

static func tem_chao(point: Vector2, solo: TileMap) -> bool:
	if not solo: return true
	var cell = solo.local_to_map(solo.to_local(point));
	return solo.get_cell_source_id(GROUND_LAYER, cell) != -1;

#region PROGRESSÃO POR TEMPO
#Sorteia uma criatura entre as já liberadas no tempo atual de partida.
#creatures[i] é liberada no minuto unlock_minutes[i] e tem chance relativa weights[i]
#(listas vazias/menores = liberada desde o início e peso 1). Retorna null se nada estiver liberado.
static func escolher_criatura(creatures: Array, unlock_minutes: Array, weights: Array) -> PackedScene:
	var minutes = GameManager.time_elapsed / 60.0;
	var total: float = 0.0;
	var available = [];
	for i in creatures.size():
		var unlock = unlock_minutes[i] if i < unlock_minutes.size() else 0.0;
		if minutes < unlock: continue
		var weight = weights[i] if i < weights.size() else 1.0;
		if weight <= 0.0: continue
		available.append([creatures[i], weight]);
		total += weight;
	if available.is_empty(): return null

	var roll = randf() * total;
	for entry in available:
		roll -= entry[1];
		if roll <= 0.0:
			return entry[0];
	return available.back()[0];
#endregion

#region DROPS
#Raio livre para o corpo do player encostar no item
const PICKUP_RADIUS = 16.0;
#Centro da área de coleta em relação à origem do item (gold/bife)
const PICKUP_OFFSET = Vector2(0, -12);

#O player consegue chegar até o item neste ponto?
static func ponto_coletavel(world_node: Node2D, point: Vector2, solo: TileMap = null) -> bool:
	var center = point + PICKUP_OFFSET;
	if not tem_chao(center, solo): return false
	var circle = CircleShape2D.new();
	circle.radius = PICKUP_RADIUS;
	var parameters = PhysicsShapeQueryParameters2D.new();
	parameters.shape = circle;
	parameters.transform = Transform2D(0.0, center);
	parameters.collision_mask = BLOCKING_MASK;
	return world_node.get_world_2d().direct_space_state.intersect_shape(parameters, 1).is_empty();

#Usa o ponto desejado se for coletável; senão procura em volta do ponto seguro
#(onde o inimigo estava, que é andável) e, em último caso, usa o próprio ponto seguro
static func ajustar_drop(world_node: Node2D, desired: Vector2, safe_point: Vector2) -> Vector2:
	var solo = find_solo(world_node.get_tree());
	if ponto_coletavel(world_node, desired, solo): return desired
	for radius in [0.0, 20.0, 40.0, 60.0, 80.0]:
		for k in 8:
			var point = safe_point + Vector2.RIGHT.rotated(TAU * k / 8.0) * radius;
			if ponto_coletavel(world_node, point, solo): return point
	return safe_point;

static func find_solo(tree: SceneTree) -> TileMap:
	if tree.current_scene == null: return null
	return tree.current_scene.get_node_or_null("Solo");
#endregion

#Remove da lista as criaturas que já morreram
static func vivos(spawned: Array) -> Array:
	return spawned.filter(func(creature): return is_instance_valid(creature) and not creature.is_queued_for_deletion());
