class_name Player
extends CharacterBody2D

@onready var animation_player: AnimationPlayer = $AnimationPlayer ;
@onready var area_da_espada: Area2D = $AreaEspada;
@onready var hitbox_area: Area2D = $HitboxArea;
@onready var health_progress_bar: ProgressBar = $HealthProgressBar;

@export_category("Movement")
@export var speed: float = 3;

@export_category("Sword")
@export var attack_player = 10;

@export_category("Ritual")
@export var ritual_damage: int = 20;
@export var ritual_interval: float = 30;
@export var ritual_scene: PackedScene;
@export var ritual_cooldown: float = 0.0;
var input_spell: bool

@export_category("Inventory")
@export var gold_in_bag: int = 0;

@export_category("Life")
@export var health: float = 100.0;
@export var max_health: float = health;
@export var death_prefab: PackedScene
@export var hitbox_cooldown: float = 0;


var input_vector: Vector2 = Vector2(0, 0);
var is_running: bool = false;
var was_running: bool = false;
var is_attacking: bool = false;
var attack_cooldown: float = 0.0;
var attack_direction: Vector2;

signal gold_colected(value: int); #Player emitie sinal quando pega gold

func _ready():
	GameManager.player = self;
	GameManager.gold_counter = gold_in_bag;
	gold_colected.connect(func(value: int) : GameManager.gold_counter +=1 );

func _process(delta: float) -> void:
	GameManager.player_position = position;
	read_input();
	update_attack_cooldown(delta);
	if Input.is_action_just_pressed("attack_1"):
		attack();
	#Precossar animação e rotação sprite
	play_run_idle_animation();
	if not is_attacking:
		rotate_animation();
	#PROCESSAR DANO
	update_hitbox_detection(delta);
	#RITUAL
	input_spell = Input.is_action_just_pressed("sacred_spell")
	update_ritual(delta, input_spell);
	
	#ATUALIZAR BARRA DE VIDA
	health_progress_bar.max_value = max_health;
	health_progress_bar.value = health;

func _physics_process(delta: float) -> void:
#MODIFICAR VELOCIDADE
	var target_velocity = input_vector * speed * 100.0;
	if is_attacking:
		target_velocity *=  0.25;
	velocity = lerp( velocity , target_velocity , 0.05 )
	move_and_slide()

func update_attack_cooldown(delta) -> void:
	# Atualizar temporizador do ataque
	if is_attacking:	
		attack_cooldown -= delta;
		if attack_cooldown <= 0.0:
			is_attacking = false;
			is_running = false;
			animation_player.play("Idle")

func rotate_animation() -> void:
	#GIRAR SPRITE
	if input_vector.x > 0:
		$Sprite2D.flip_h = false;
	elif input_vector.x < 0:
		$Sprite2D.flip_h = true;

func play_run_idle_animation() -> void:
	#ANIMAÇÕES
	if not is_attacking:
		if was_running != is_running:
			if is_running:
				animation_player.play("Run");
			else:
				animation_player.play("Idle");

func read_input() -> void:
	#OBTER INPUT VECTOR
	input_vector = Input.get_vector( "move_left" , "move_right" , "move_up" , "move_down" );
	#DEADZONE
	var deadzone = 0.15
	if abs(input_vector.x) < 0.15:
		input_vector.x = 0.0
	if abs(input_vector.y) < 0.15:
		input_vector.y = 0.0;

	#ATUALIZAR IS_RUNNING
	was_running = is_running;
	is_running = not input_vector.is_zero_approx();

func attack() -> void:
	var a = RandomNumberGenerator.new();
	if is_attacking:
		return;
	else:
		#attack_side_1 (1,0) ou (-1,0)
		if input_vector == Vector2(0,1):
			animation_player.play( "Attack_down_" + str(a.randi_range(1,2)) );
			attack_direction = Vector2.DOWN

		elif input_vector == Vector2(0,-1):
			animation_player.play( "Attack_up_"+ str(a.randi_range(1,2)) );
			attack_direction = Vector2.UP;

		else:
			animation_player.play( ( "Attack_side_" + str(a.randi_range(1,2))) );
			if $Sprite2D.flip_h:
				attack_direction = Vector2.LEFT;
			else:
				attack_direction = Vector2.RIGHT;

		#Configurar temporizador
		attack_cooldown = 0.6;

		# Marcar que esta atacando
		is_attacking = true;
		Sfx.play("sword_swing");

func deal_damage_to_enemies():
	var bodies = area_da_espada.get_overlapping_bodies();
	var a = RandomNumberGenerator.new();
	var hit_enemy = false;
	for body in bodies:
		if body.is_in_group("enemies"):
			var enemy: Enemy = body
			var direction_to_enemy = (enemy.position - position).normalized();
			var dot_product = direction_to_enemy.dot(attack_direction);
			if dot_product > 0.3:
				enemy.damage(attack_player * a.randf());
				hit_enemy = true;
		elif body.is_in_group("estruturas"):
			#Casas dos goblins (o corpo de colisão é filho da casa)
			var direction_to_structure = (body.global_position - global_position).normalized();
			if direction_to_structure.dot(attack_direction) > 0.0:
				body.owner.damage(attack_player * a.randf());
	if hit_enemy:
		Sfx.play("sword_hit");

func update_hitbox_detection(delta):
	#TEMPORIZADOR
	hitbox_cooldown -= delta
	if hitbox_cooldown > 0 : return
	#FREQUENCIA (2x por segindo)
	hitbox_cooldown = 1
	#Processar HitboxArea
	var bodies = hitbox_area.get_overlapping_bodies();
	for body in bodies:
		if body.is_in_group("enemies"):
			var enemy: Enemy = body
			var damage_amout = enemy.attack_enemy
			damage(damage_amout);
	pass

func damage(amout: int):
	if health <= 0: return
	
	modulate = Color.RED;
	var tween = create_tween();
	tween.set_ease(Tween.EASE_IN);
	tween.set_trans(Tween.TRANS_QUINT);
	tween.tween_property(self, "modulate", Color.WHITE, 0.3);
	
	health -= amout;
	print("Player recebeu dano de ", amout, ". A vida restante é ", health,"/",max_health);
	if health <= 0:
		die();
	else:
		Sfx.play("player_hurt");

func die():
	Sfx.play("player_death");
	GameManager.end_game();
	if death_prefab:
		var death_object = death_prefab.instantiate();
		death_object.global_position = position;
		get_parent().add_child(death_object);
	
	print("Player morreu!")
	queue_free();

func heal(amout: int) -> int:
	health += amout
	if health > max_health: health = max_health;
	print("Player regenerou ", amout ," de vida.", health,"/",max_health);
	return health

func update_ritual(delta, input):
	# Atualizar temporizador
	ritual_cooldown -= delta
	if ritual_cooldown > 0: return
	if input:
		call_ritual();
		ritual_cooldown = ritual_interval

func call_ritual():
# Criar ritual
	var ritual = ritual_scene.instantiate()
	ritual.damage_amout = ritual_damage;
	add_child(ritual);
	Sfx.play("ritual_cast");

func obtain_gold(amout: int) -> int:
	gold_in_bag += amout
	print("Player obteve ", amout," de gold. Sua bag contém: ",gold_in_bag,".");
	return gold_in_bag
