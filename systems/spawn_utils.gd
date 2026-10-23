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

#ANIMAÇÃO DE DROP: o item voa em arco de "from" até a posição onde já está,
#crescendo; ao pousar toca a animação de surgir/quicar (G_Spawn/M_Spawn) uma vez.
#Só pode ser coletado depois de pousar.
const DROP_FLIGHT_TIME = 0.45;
#Marca que o item ainda está no ar (não pode ser coletado)
const DROP_IN_AIR = &"drop_no_ar";
const DROP_ARC_HEIGHT = 36.0;

#Marca o item como "no ar" ANTES de ele entrar na cena, para o _ready dele já
#saber que vai cair (ex.: a poção só começa a flutuar depois de pousar)
static func marcar_no_ar(item: Node):
	item.set_meta(DROP_IN_AIR, true);

static func animar_drop(item: Node2D, from: Vector2, delay: float = 0.0):
	var target = item.position;
	var final_scale = item.scale;
	var area: Area2D = item.get_node_or_null("Area2D");
	if area: area.set_deferred("monitoring", false);
	#Trava imediata (o monitoring só desliga no próximo quadro)
	item.set_meta(DROP_IN_AIR, true);

	item.position = from;
	item.scale = final_scale * 0.4;
	if item is AnimatedSprite2D:
		item.stop();
		item.frame = 0;

	#Sequência: espera (opcional) -> voo em arco + crescer juntos -> pousar
	var tween = item.create_tween();
	if delay > 0.0: tween.tween_interval(delay);
	tween.tween_method(func(t: float):
		item.position = from.lerp(target, t) + Vector2(0, -sin(PI * t) * DROP_ARC_HEIGHT),
		0.0, 1.0, DROP_FLIGHT_TIME);
	tween.parallel().tween_property(item, "scale", final_scale, DROP_FLIGHT_TIME).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT);
	tween.tween_callback(func(): pousar_drop(item, area));

static func pousar_drop(item: Node2D, area: Area2D):
	item.remove_meta(DROP_IN_AIR);
	#Religar a área detecta de novo quem já estiver em cima do item
	if area: area.monitoring = true;
	if item is AnimatedSprite2D and item.sprite_frames:
		var anim = item.animation;
		#Toca a animação de surgir/quicar uma vez e para no último quadro
		item.sprite_frames.set_animation_loop(anim, false);
		item.play(anim);
	elif item.has_method("animar_pouso"):
		#Itens sem folha de animação (ex.: poção) fazem o próprio quique
		item.animar_pouso();

#QUIQUE ao pousar (para itens sem folha de animação, como poção e moeda):
#amassa, salta duas vezes e assenta. Chama "ao_terminar" no fim.
static func quicar_sprite(sprite: Node2D, base_y: float, ao_terminar: Callable):
	var base_scale = sprite.scale;
	var tween = sprite.create_tween();
	tween.tween_property(sprite, "scale", base_scale * Vector2(1.3, 0.7), 0.06);
	tween.tween_property(sprite, "scale", base_scale * Vector2(0.85, 1.2), 0.08);
	tween.parallel().tween_property(sprite, "position:y", base_y - 14.0, 0.12).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD);
	tween.tween_property(sprite, "scale", base_scale, 0.08);
	tween.parallel().tween_property(sprite, "position:y", base_y, 0.12).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD);
	tween.tween_property(sprite, "scale", base_scale * Vector2(1.15, 0.85), 0.05);
	tween.tween_property(sprite, "position:y", base_y - 5.0, 0.08).set_ease(Tween.EASE_OUT);
	tween.parallel().tween_property(sprite, "scale", base_scale, 0.08);
	tween.tween_property(sprite, "position:y", base_y, 0.08).set_ease(Tween.EASE_IN);
	tween.tween_callback(ao_terminar);

static func find_solo(tree: SceneTree) -> TileMap:
	if tree.current_scene == null: return null
	return tree.current_scene.get_node_or_null("Solo");
#endregion

#Remove da lista as criaturas que já morreram
static func vivos(spawned: Array) -> Array:
	return spawned.filter(func(creature): return is_instance_valid(creature) and not creature.is_queued_for_deletion());
