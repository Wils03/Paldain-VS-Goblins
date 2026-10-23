extends Node

@export var speed: float = 0.8;
#Faixa de distância do player: abaixo de min_distance o goblin recua,
#acima de max_distance ele se aproxima, e só arremessa até throw_range
@export var min_distance: float = 160.0;
@export var max_distance: float = 260.0;
@export var throw_range: float = 320.0;
@export var throw_cooldown: float = 2.5;
@export var dynamite_scene: PackedScene;
@export var dynamite_damage: int = 5;

#Frame da animação "Throw" em que a dinamite sai da mão
const THROW_RELEASE_FRAME = 4;

var sprite: AnimatedSprite2D;
var input_vector: Vector2;
var enemy: Enemy;
var cooldown: float = 0.0;
var is_throwing: bool = false;

func _ready():
	enemy = get_parent()
	sprite = enemy.get_node("AnimatedSprite2D");
	sprite.frame_changed.connect(on_frame_changed);
	sprite.animation_finished.connect(on_animation_finished);
	#Evitar que todos os goblins arremessem ao mesmo tempo
	cooldown = randf_range(0.5, throw_cooldown);

func _physics_process(delta):
	#Iginorar GameOver
	if GameManager.is_game_over:
		sprite.play("Idle");
		return;

	cooldown -= delta;
	var diference = GameManager.player_position - enemy.position;
	var distance = diference.length();
	input_vector = diference.normalized();
	rotate_animation();

	if is_throwing: return

	#ARREMESSAR (nunca colado no player nem longe demais)
	if distance >= min_distance and distance <= throw_range and cooldown <= 0.0:
		start_throw();
		return;

	#MANTER A FAIXA DE DISTÂNCIA
	if distance > max_distance:
		move(input_vector);
	elif distance < min_distance:
		move(-input_vector);
	else:
		#Parado na faixa, mas ainda se afasta suavemente dos vizinhos
		var separation = enemy.get_separation().limit_length(1.0);
		enemy.velocity = separation * speed * 100.0;
		enemy.move_and_slide();
		sprite.play("Idle");

func move(direction: Vector2):
	var steering = (direction + enemy.get_separation()).limit_length(1.0);
	enemy.move_with_detour(steering * speed * 100.0, get_physics_process_delta_time());
	sprite.play("Run");

func start_throw():
	is_throwing = true;
	cooldown = throw_cooldown;
	sprite.play("Throw");

func on_frame_changed():
	if not is_throwing or sprite.animation != "Throw": return
	if sprite.frame == THROW_RELEASE_FRAME:
		spawn_dynamite();

func on_animation_finished():
	if sprite.animation == "Throw":
		is_throwing = false;
		sprite.play("Idle");

func spawn_dynamite():
	if not dynamite_scene: return
	var dynamite = dynamite_scene.instantiate();
	dynamite.start_position = enemy.position + Vector2(0, -30);
	dynamite.target_position = GameManager.player_position;
	dynamite.damage_amout = dynamite_damage;
	enemy.get_parent().add_child(dynamite);
	Sfx.play("dynamite_fuse", -6.0);

func rotate_animation() -> void:
	#GIRAR SPRITE
	if input_vector.x > 0:
		sprite.flip_h = false;
	elif input_vector.x < 0:
		sprite.flip_h = true;
