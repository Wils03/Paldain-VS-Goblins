extends Node

#Reparador: procura a casa dos goblins destruída mais próxima, vai até a porta
#e martela até ela voltar a funcionar. Sem mais nada para consertar, volta para
#uma casa e entra pela porta (sai do jogo sem contar como abate).

@export var speed: float = 1.2;
#Vida devolvida à casa por segundo de conserto
@export var repair_per_second: float = 8.0;
#Distância da porta para começar a martelar / para entrar na casa
@export var work_distance: float = 30.0;

var sprite: AnimatedSprite2D;
var enemy: Enemy;
var target_house: Node2D;
#Última casa consertada: é para ela que o reparador volta
var home_house: Node2D;
var input_vector: Vector2;
var is_entering: bool = false;

func _ready():
	enemy = get_parent()
	sprite = enemy.get_node("AnimatedSprite2D");

func _physics_process(delta):
	#Já está entrando na casa: só espera a animação terminar
	if is_entering: return

	#Iginorar GameOver
	if GameManager.is_game_over:
		sprite.play("Idle");
		return;

	#ESCOLHER A CASA ALVO
	if not is_instance_valid(target_house) or not target_house.is_destroyed:
		target_house = find_nearest_destroyed_house();

	#Nada para consertar: volta para casa e entra
	if not target_house:
		go_home();
		return;

	var work_point = target_house.get_repair_point();
	var diference = work_point - enemy.position;
	input_vector = diference.normalized();

	if diference.length() > work_distance:
		#ANDAR ATÉ A PORTA
		move(input_vector);
		sprite.play("Run");
		rotate_animation(input_vector.x);
	else:
		#MARTELAR
		move(Vector2.ZERO);
		sprite.play("Repair");
		rotate_animation(target_house.global_position.x - enemy.position.x);
		home_house = target_house;
		target_house.repair(repair_per_second * delta);

#VOLTAR PARA CASA: anda até a porta e entra
func go_home():
	if not is_instance_valid(home_house):
		home_house = find_nearest_house();
	if not home_house:
		move(Vector2.ZERO);
		sprite.play("Idle");
		return

	var diference = home_house.get_repair_point() - enemy.position;
	input_vector = diference.normalized();
	if diference.length() > work_distance:
		move(input_vector);
		sprite.play("Run");
		rotate_animation(input_vector.x);
		return

	#ENTRAR PELA PORTA
	is_entering = true;
	enemy.velocity = Vector2.ZERO;
	sprite.play("Run");
	enemy.remove_from_group("origem_" + Enemy.ORIGEM_REPARADOR);
	GoblinHouse.animar_entrada(enemy, home_house.get_door_point());

func move(direction: Vector2):
	var steering = (direction + enemy.get_separation()).limit_length(1.0);
	enemy.move_with_detour(steering * speed * 100.0, get_physics_process_delta_time());

func find_nearest_destroyed_house() -> Node2D:
	return find_nearest(func(house): return house.is_destroyed);

func find_nearest_house() -> Node2D:
	return find_nearest(func(house): return not house.is_destroyed);

func find_nearest(filter: Callable) -> Node2D:
	var nearest: Node2D = null;
	var nearest_distance = INF;
	for house in get_tree().get_nodes_in_group("goblin_houses"):
		if not filter.call(house): continue
		var distance = enemy.position.distance_to(house.global_position);
		if distance < nearest_distance:
			nearest = house;
			nearest_distance = distance;
	return nearest;

func rotate_animation(direction_x: float) -> void:
	#GIRAR SPRITE
	if direction_x > 0:
		sprite.flip_h = false;
	elif direction_x < 0:
		sprite.flip_h = true;
