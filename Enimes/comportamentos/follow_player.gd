extends Node

@export var speed: float = 2.0;

@export_category("Animações")
#Animação enquanto persegue o player
@export var run_animation: String = "Run";
#Animações de ataque enquanto encostado no player (vazio = sem ataque).
#Se a de cima/baixo estiver vazia, usa a de lado.
@export var attack_side_animation: String = "";
@export var attack_up_animation: String = "";
@export var attack_down_animation: String = "";

var sprite: AnimatedSprite2D;
var input_vector: Vector2;
var enemy: Enemy;

func _ready():
	enemy = get_parent()
	sprite = enemy.get_node("AnimatedSprite2D");
	enemy.health
	

func _physics_process(delta):
	#Iginorar GameOver
	if GameManager.is_game_over: return;
	
	var player_position = GameManager.player_position;
	var diference = player_position - enemy.position;
	input_vector = diference.normalized();

	#SEPARAÇÃO SUAVE dos outros inimigos e do centro do player
	var separation = enemy.get_separation();

	#PARAR AO ENCOSTAR NO PLAYER (já está na hitbox, causando dano)
	var chase = input_vector;
	var touching = esta_encostado();
	play_animation(touching);
	if touching:
		chase = Vector2.ZERO;
		#Encostado, não recua por causa dos vizinhos: só desliza para os lados,
		#assim o cerco não abre buracos
		var outward = separation.dot(-input_vector);
		if outward > 0.0:
			separation += input_vector * outward;

	var steering = (chase + separation).limit_length(1.0);
	if touching:
		#Encostado no player: só se ajusta ao lado dos vizinhos, sem desvio
		enemy.velocity = steering * speed * 100.0
		enemy.move_and_slide();
	else:
		#Perseguindo: contorna casas, árvores e paredes se travar
		enemy.move_with_detour(steering * speed * 100.0, delta);
	rotate_animation();

#ATACAR quando encostado no player, CORRER quando persegue
func play_animation(touching: bool):
	var animation = run_animation;
	if touching and attack_side_animation != "":
		animation = attack_side_animation;
		#Player mais acima/abaixo do que para o lado: ataque vertical
		if absf(input_vector.y) > absf(input_vector.x):
			var vertical = attack_up_animation if input_vector.y < 0 else attack_down_animation;
			if vertical != "":
				animation = vertical;
	if sprite.sprite_frames.has_animation(animation) and sprite.animation != animation:
		sprite.play(animation);

func esta_encostado() -> bool:
	var player = GameManager.player;
	if not player or not is_instance_valid(player): return false
	return player.hitbox_area.overlaps_body(enemy);

func rotate_animation() -> void:
	#GIRAR SPRITE
	if input_vector.x > 0:
		sprite.flip_h = false;
	elif input_vector.x < 0:
		sprite.flip_h = true;
