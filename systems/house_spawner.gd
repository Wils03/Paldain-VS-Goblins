class_name GoblinHouse
extends Sprite2D

#Spawner fixo: a casa solta goblins pela porta continuamente.
#Pode ser destruída pelo player e consertada por goblins reparadores.

@export_category("Spawn")
@export var creatures: Array[PackedScene];
#PROGRESSÃO: minuto de partida em que cada criatura (mesma ordem de "creatures") começa a sair
@export var liberar_no_minuto: Array[float];
#Chance relativa de cada criatura entre as já liberadas
@export var pesos: Array[float];
#Segundos entre cada goblin que sai da casa
@export var spawn_interval: float = 8.0;
#Máximo de goblins vivos desta casa (0 = sem limite)
@export var max_mobs: int = 0;
#Pontos de saída em volta da porta (relativos ao centro da casa)
@export var exit_points: Array[Vector2] = [Vector2(0, 100), Vector2(-45, 95), Vector2(45, 95), Vector2(0, 130)];

@export_category("Vida")
@export var max_health: float = 100.0;
@export var destroyed_texture: Texture2D;
#Recompensa ao destruir (ex.: ouro) e quantas unidades
@export var reward_scene: PackedScene;
@export var reward_amount: int = 3;

@export_category("Conserto")
@export var repairer_scene: PackedScene;
#Segundos entre cada reparador enviado por uma casa inteira
@export var repairer_interval: float = 10.0;
#Reconstrói sozinha após este tempo destruída (0 = só com reparador)
@export var auto_rebuild_time: float = 90.0;

@onready var health_bar: ProgressBar = $HealthProgressBar;

const GROUP_HOUSES = "goblin_houses";

var health: float;
var is_destroyed: bool = false;
var intact_texture: Texture2D;
var cooldown: float = 0.0;
var repairer_cooldown: float = 0.0;
var destroyed_time: float = 0.0;
var spawned: Array = [];
var health_fill: StyleBoxFlat;

const COLOR_LIFE = Color(0.6, 0, 0);
const COLOR_REPAIR = Color(0.95, 0.75, 0.1);

func _ready():
	add_to_group(GROUP_HOUSES);
	health = max_health;
	#Cada casa tem o próprio estilo de preenchimento (a cor muda no conserto)
	health_fill = health_bar.get_theme_stylebox("fill").duplicate();
	health_bar.add_theme_stylebox_override("fill", health_fill);
	intact_texture = texture;
	#Casas não soltam goblins todas no mesmo instante
	cooldown = randf_range(0.0, spawn_interval);
	repairer_cooldown = randf_range(0.0, repairer_interval);
	update_health_bar();

func _process(delta):
	#Iginorar GameOver
	if GameManager.is_game_over: return;

	if is_destroyed:
		destroyed_time += delta;
		if auto_rebuild_time > 0.0 and destroyed_time >= auto_rebuild_time:
			rebuild();
		return

	update_repairers(delta);
	update_spawn(delta);

#region SPAWN
func update_spawn(delta):
	if creatures.is_empty(): return
	#Temporizador (cooldown)
	cooldown -= delta;
	if cooldown > 0: return
	cooldown = spawn_interval;

	#LIMITE OPCIONAL
	if max_mobs > 0:
		spawned = SpawnUtils.vivos(spawned);
		if spawned.size() >= max_mobs: return

	#Só criaturas já liberadas pelo tempo de partida E com vaga na fase atual do
	#MobSpawner (o limite de inimigos no mapa vale também para as casas, e parte
	#de cada cota fica reservada para nascer perto do player)
	var spawner = get_tree().get_first_node_in_group(MobSpawner.GROUP);
	var opcoes = [];
	var minutos = [];
	var chances = [];
	for i in creatures.size():
		if spawner and not spawner.casa_pode_soltar(creatures[i]): continue
		opcoes.append(creatures[i]);
		minutos.append(liberar_no_minuto[i] if i < liberar_no_minuto.size() else 0.0);
		chances.append(pesos[i] if i < pesos.size() else 1.0);
	var scene = SpawnUtils.escolher_criatura(opcoes, minutos, chances);
	if not scene: return
	var creature = spawn_at_door(scene, Enemy.ORIGEM_CASA);
	if creature and max_mobs > 0:
		spawned.append(creature);

#Envia um reparador se houver mais casas destruídas do que reparadores vivos
func update_repairers(delta):
	if not repairer_scene: return
	repairer_cooldown -= delta;
	if repairer_cooldown > 0: return
	repairer_cooldown = repairer_interval;

	var destroyed_houses = get_destroyed_houses(get_tree()).size();
	var repairers = Enemy.contar_vivos(get_tree(), Enemy.ORIGEM_REPARADOR);
	if destroyed_houses > repairers:
		spawn_at_door(repairer_scene, Enemy.ORIGEM_REPARADOR);

func spawn_at_door(scene: PackedScene, origem: String) -> Node2D:
	var creature: Node2D = scene.instantiate();
	var point = pegar_saida_livre(creature);
	if point == Vector2.INF:
		#Porta bloqueada (ex.: inimigo ou parede): tenta de novo no próximo ciclo
		creature.queue_free();
		return null

	creature.global_position = point;
	creature.set_origem(origem);
	get_tree().current_scene.add_child(creature);
	#Sai pela porta em vez de "brotar" do nada
	animar_saida(creature, get_door_point());
	return creature;

func pegar_saida_livre(creature: Node2D) -> Vector2:
	var points = exit_points.duplicate();
	points.shuffle();
	for offset in points:
		var point = to_global(offset);
		if SpawnUtils.ponto_valido(self, point, creature):
			return point;
	return Vector2.INF;
#endregion

#region VIDA E CONSERTO
func damage(amount: float):
	if amount <= 0: return
	#Destruída: o dano desfaz o progresso do conserto
	health = max(health - amount, 0.0);
	flash(Color.RED);
	show_damage_digit(amount);
	if not is_destroyed and health <= 0.0:
		destroy();
	else:
		Sfx.play("house_hit");
	update_health_bar();

func destroy():
	is_destroyed = true;
	destroyed_time = 0.0;
	health = 0.0;
	if destroyed_texture:
		texture = destroyed_texture;
	Sfx.play("house_destroyed");
	drop_reward();
	update_health_bar();

#Chamado pelo reparador a cada frame enquanto martela
func repair(amount: float):
	if not is_destroyed: return
	health = min(health + amount, max_health);
	if health >= max_health:
		rebuild();
	update_health_bar();

func rebuild():
	is_destroyed = false;
	health = max_health;
	texture = intact_texture;
	cooldown = spawn_interval;
	flash(Color(1.6, 1.6, 1.6));
	Sfx.play("house_repaired");
	update_health_bar();

#Ponto em frente à porta onde o reparador trabalha
func get_repair_point() -> Vector2:
	return to_global(Vector2(0, 95));

#Porta da casa (onde os personagens aparecem/somem)
func get_door_point() -> Vector2:
	return to_global(DOOR_OFFSET);

#region ANIMAÇÕES DE PORTA
const DOOR_OFFSET = Vector2(0, 55);
const DOOR_ANIMATION_TIME = 0.5;

#Personagem "sai pela porta": começa pequeno e transparente na porta e anda até o lugar
static func animar_saida(creature: Node2D, door: Vector2):
	var sprite: Node2D = creature.get_node_or_null("AnimatedSprite2D");
	if not sprite: return
	var final_position = sprite.position;
	var final_scale = sprite.scale;
	sprite.position = final_position + (door - creature.global_position);
	sprite.scale = final_scale * 0.5;
	sprite.modulate.a = 0.0;
	var tween = sprite.create_tween().set_parallel(true).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD);
	tween.tween_property(sprite, "position", final_position, DOOR_ANIMATION_TIME);
	tween.tween_property(sprite, "scale", final_scale, DOOR_ANIMATION_TIME);
	tween.tween_property(sprite, "modulate:a", 1.0, DOOR_ANIMATION_TIME * 0.6);

#Personagem "entra pela porta": encolhe, vai até a porta e some; depois sai do jogo
static func animar_entrada(creature: Node2D, door: Vector2):
	var sprite: Node2D = creature.get_node_or_null("AnimatedSprite2D");
	if not sprite:
		creature.queue_free();
		return
	var tween = sprite.create_tween().set_parallel(true).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD);
	tween.tween_property(sprite, "position", sprite.position + (door - creature.global_position), DOOR_ANIMATION_TIME);
	tween.tween_property(sprite, "scale", sprite.scale * 0.5, DOOR_ANIMATION_TIME);
	tween.tween_property(sprite, "modulate:a", 0.0, DOOR_ANIMATION_TIME);
	tween.chain().tween_callback(creature.queue_free);
#endregion

static func get_destroyed_houses(tree: SceneTree) -> Array:
	return tree.get_nodes_in_group(GROUP_HOUSES).filter(func(house): return house.is_destroyed);

func update_health_bar():
	if not health_bar: return
	health_bar.max_value = max_health;
	health_bar.value = health;
	#Barra só aparece com a casa danificada ou em conserto
	health_bar.visible = health < max_health;
	#Vermelha = vida, amarela = progresso do conserto
	if health_fill:
		health_fill.bg_color = COLOR_REPAIR if is_destroyed else COLOR_LIFE;

func drop_reward():
	if not reward_scene: return
	for i in reward_amount:
		var reward = reward_scene.instantiate();
		var desired = to_global(Vector2(randf_range(-40, 40), randf_range(80, 120)));
		#Em frente à porta, num lugar que o player alcança
		reward.position = SpawnUtils.ajustar_drop(self, desired, get_repair_point());
		get_tree().current_scene.add_child(reward);

func flash(color: Color):
	modulate = color;
	var tween = create_tween();
	tween.tween_property(self, "modulate", Color.WHITE, 0.3);

func show_damage_digit(amount: float):
	var damage_digit = preload("res://Misc/damage_digit.tscn").instantiate();
	damage_digit.value = int(amount);
	damage_digit.global_position = to_global(Vector2(0, -60));
	get_tree().current_scene.add_child(damage_digit);
#endregion
