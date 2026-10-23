extends Node2D

@export var damage_amout: int = 5;
@export var explosion_radius: float = 70.0;
@export var flight_time: float = 0.8;
@export var arc_height: float = 120.0;

@onready var dynamite_sprite: AnimatedSprite2D = $DynamiteSprite;
@onready var explosion_sprite: AnimatedSprite2D = $ExplosionSprite;

var start_position: Vector2;
var target_position: Vector2;
var elapsed: float = 0.0;
var exploded: bool = false;
var flight_offset: Vector2;

func _ready():
	#O nó fica no alvo; só o sprite da dinamite viaja até ele
	position = target_position;
	flight_offset = start_position - target_position;
	dynamite_sprite.position = flight_offset;
	dynamite_sprite.play("Fuse");
	explosion_sprite.visible = false;
	explosion_sprite.animation_finished.connect(queue_free);

func _process(delta):
	if exploded: return;
	elapsed += delta;
	var t: float = clamp(elapsed / flight_time, 0.0, 1.0);

	#TRAJETÓRIA EM ARCO
	var height = sin(t * PI) * arc_height;
	dynamite_sprite.position = flight_offset.lerp(Vector2.ZERO, t) + Vector2(0, -height);
	dynamite_sprite.rotation += delta * 12.0;
	queue_redraw();

	if t >= 1.0:
		explode();

func _draw():
	#MARCAR ONDE A DINAMITE VAI CAIR
	if exploded: return;
	var t: float = clamp(elapsed / flight_time, 0.0, 1.0);
	draw_circle(Vector2.ZERO, explosion_radius, Color(1.0, 0.2, 0.1, 0.1 + 0.15 * t));
	draw_arc(Vector2.ZERO, explosion_radius, 0.0, TAU, 32, Color(1.0, 0.3, 0.1, 0.7), 2.0);

func explode():
	exploded = true;
	queue_redraw();
	dynamite_sprite.visible = false;
	explosion_sprite.visible = true;
	explosion_sprite.play("Explode");
	Sfx.play("explosion");

	if GameManager.is_game_over: return
	var player = GameManager.player;
	if player and is_instance_valid(player):
		if player.global_position.distance_to(global_position) <= explosion_radius:
			player.damage(damage_amout);
