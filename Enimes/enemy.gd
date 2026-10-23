class_name Enemy
extends CharacterBody2D

@export var attack_enemy: int = 1;
@export_category("Life")
@export var health: float = 10.0
@export var death_prefab: PackedScene
var damage_digit_prefab: PackedScene

@export_category("Drops")
@export var drop_chance: float = 0.5;

@export_category("Som")
#Nome do efeito em Audio/sfx/ tocado ao morrer (vazio = sem som)
@export var death_sound: String = "goblin_death";
@onready var loot: Node =$Loot
@onready var damage_digit_marker = $DamageDigitMarker

#ORIGEM DO SPAWN: quem criou este inimigo ("mob_spawner", "casa" ou vazio)
const ORIGEM_MOB_SPAWNER = "mob_spawner";
const ORIGEM_CASA = "casa";
const ORIGEM_REPARADOR = "reparador";
var origem: String = "";

#Marca a origem e coloca no grupo "origem_<nome>" para os spawners contarem
func set_origem(nova_origem: String):
	origem = nova_origem;
	add_to_group("origem_" + nova_origem);

static func contar_vivos(tree: SceneTree, nome_origem: String) -> int:
	var total = 0;
	for enemy in tree.get_nodes_in_group("origem_" + nome_origem):
		if not enemy.is_queued_for_deletion():
			total += 1;
	return total;

@export_category("Separation")
#Distância em que um inimigo começa a afastar o outro
@export var separation_radius: float = 40.0;
#Força do afastamento entre inimigos (0 = desligado)
@export var separation_strength: float = 0.8;
#Raio em volta do centro do player onde o inimigo é empurrado para fora.
#Pequeno de propósito: só evita inimigo "dentro" do player, sem abrir o cerco
@export var player_personal_space: float = 10.0;

#GRADE ESPACIAL compartilhada: reconstruída uma vez por frame de física
const GRID_CELL: float = 64.0;
static var grid: Dictionary = {};
static var grid_frame: int = -1;

func _ready():
	damage_digit_prefab = preload("res://Misc/damage_digit.tscn")

static func rebuild_grid(tree: SceneTree):
	var frame = Engine.get_physics_frames();
	if grid_frame == frame: return
	grid_frame = frame;
	grid.clear();
	for other in tree.get_nodes_in_group("enemies"):
		var key = Vector2i((other.global_position / GRID_CELL).floor());
		if not grid.has(key): grid[key] = [];
		grid[key].append(other);

#Direção (não normalizada) para se afastar dos vizinhos e do player
func get_separation() -> Vector2:
	rebuild_grid(get_tree());
	var push = Vector2.ZERO;
	var key = Vector2i((global_position / GRID_CELL).floor());
	for x in range(-1, 2):
		for y in range(-1, 2):
			for other in grid.get(key + Vector2i(x, y), []):
				if other == self or not is_instance_valid(other): continue
				push += repel_from(other.global_position, separation_radius) * separation_strength;

	#ESPAÇO PESSOAL DO PLAYER (não ficar dentro do personagem)
	if GameManager.player and is_instance_valid(GameManager.player):
		push += repel_from(GameManager.player_position, player_personal_space) * 2.0;
	return push;

#DESVIO DE OBSTÁCULOS: tempo que ainda falta contornando e a direção do contorno
var detour_dir: Vector2 = Vector2.ZERO;
var detour_time: float = 0.0;
const DETOUR_DURATION = 0.6;

#Move com a velocidade desejada; se travar numa parede/casa/árvore (não no player
#nem em outro inimigo), contorna o obstáculo por um instante e depois tenta de novo
func move_with_detour(desired_velocity: Vector2, delta: float):
	if detour_time > 0.0:
		detour_time -= delta;
		velocity = detour_dir * desired_velocity.length();
	else:
		velocity = desired_velocity;
	var start = global_position;
	move_and_slide();

	if detour_time > 0.0 or desired_velocity.length() < 1.0: return
	#Andou quase nada do que queria: está travado
	if global_position.distance_to(start) > desired_velocity.length() * delta * 0.25: return
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i);
		var collider = collision.get_collider();
		if not (collider is StaticBody2D or collider is TileMap or collider is TileMapLayer): continue
		var normal = collision.get_normal();
		var tangent = normal.orthogonal();
		var side = tangent.dot(desired_velocity.normalized());
		#De frente para o obstáculo: escolhe um lado
		if absf(side) < 0.1:
			side = 1.0 if randf() < 0.5 else -1.0;
		detour_dir = (tangent * signf(side) + normal * 0.3).normalized();
		detour_time = DETOUR_DURATION;
		return

func repel_from(point: Vector2, radius: float) -> Vector2:
	var offset = global_position - point;
	var distance = offset.length();
	if distance >= radius: return Vector2.ZERO
	if distance < 0.01:
		#Exatamente no mesmo ponto: escolher uma direção aleatória
		offset = Vector2.RIGHT.rotated(randf() * TAU);
		distance = 0.01;
	return offset.normalized() * (1.0 - distance / radius);

func damage(amout: int):
	if health <= 0:
		health = 0;
		die();

	modulate = Color.RED;
	var tween = create_tween();
	tween.set_ease(Tween.EASE_IN);
	tween.set_trans(Tween.TRANS_QUINT);
	tween.tween_property(self, "modulate", Color.WHITE, 0.3);
	
	#CRIAR LABEL DAMAGE DIGIT
	var damage_digit = damage_digit_prefab.instantiate();
	damage_digit.value = amout;
	if damage_digit_marker:
		damage_digit.global_position = damage_digit_marker.global_position
	else:
		damage_digit.global_position = global_position
	get_parent().add_child(damage_digit);
	
	health -= amout;
	print("Inimigo recebeu dano de ", amout, ". A vida restante é ", health, ".");

func die():
	if death_sound != "":
		Sfx.play(death_sound);
	if death_prefab:
		var death_object = death_prefab.instantiate();
		death_object.position = position;
		get_parent().add_child(death_object)
	if randf() <= drop_chance:
			drop_item();
	GameManager.monsters_defeated_counter += 1;
	queue_free();
	
func drop_item():
	var drop: AnimatedSprite2D = loot.loot_create(position);
	get_parent().add_child(drop)
