class_name PhaseManager
extends Node

#FASES: cada fase dura um tempo fixo. Ao terminar, os inimigos somem, o ouro
#que ficou no chão é recolhido, o player volta ao início e abre a loja
#(com o jogo pausado). Ao sair da loja, começa a próxima fase.

const GROUP = "phase_manager";

#Duração de uma fase normal (segundos)
@export var duracao_fase: float = 180.0;
#Duração máxima de uma fase de boss (segundos)
@export var duracao_fase_boss: float = 300.0;
#Números das fases de boss (ex.: [5, 10]). O boss em si ainda não existe.
@export var fases_boss: Array[int] = [];
#Tempo para comprar na loja entre as fases (segundos)
@export_range(30, 60, 5, "suffix:s") var tempo_loja: float = 45.0;
@export var shop_scene: PackedScene;

var tempo_restante: float = 0.0;
var player_inicio: Vector2;

func _ready():
	add_to_group(GROUP);
	tempo_restante = duracao_da_fase(GameManager.fase_atual);
	var player = get_tree().current_scene.get_node_or_null("Player");
	if player: player_inicio = player.global_position;

func _process(delta):
	if GameManager.is_game_over or GameManager.na_loja: return
	tempo_restante -= delta;
	if tempo_restante <= 0.0:
		terminar_fase();

#ATALHOS DE TESTE (só rodando pelo editor; não existem no executável exportado)
#N = termina a fase agora e abre a loja | G = +50 de ouro
#(F9/F10 não: o editor usa essas teclas no depurador e congela o jogo)
func _unhandled_input(event):
	if not OS.is_debug_build(): return
	if not (event is InputEventKey and event.pressed and not event.echo): return
	match event.keycode:
		KEY_N:
			if not GameManager.na_loja and not GameManager.is_game_over:
				terminar_fase();
		KEY_G:
			GameManager.gold_counter += 50;
			Sfx.play("gold_pickup");

func duracao_da_fase(fase: int) -> float:
	return duracao_fase_boss if fase in fases_boss else duracao_fase;

func eh_fase_de_boss(fase: int) -> bool:
	return fase in fases_boss;

#Texto do tempo que falta na fase, ex.: "02:13"
func tempo_restante_texto() -> String:
	var segundos = maxi(ceili(tempo_restante), 0);
	return "%02d:%02d" % [segundos / 60, segundos % 60];

#FIM DA FASE
func terminar_fase():
	tempo_restante = 0.0;
	limpar_mapa();
	voltar_player_ao_inicio();
	abrir_loja();

func limpar_mapa():
	var scene = get_tree().current_scene;
	#Inimigos (inclusive reparadores) somem sem contar como abate
	for enemy in get_tree().get_nodes_in_group("enemies"):
		enemy.queue_free();
	for node in scene.get_children():
		var script = node.get_script();
		if not script: continue
		var path = script.resource_path;
		#Dinamites no ar
		if path.ends_with("dynamite.gd"):
			node.queue_free();
		#Ouro no chão (moedas e sacos) é recolhido automaticamente, pelo valor de cada um
		elif "gold_amout" in node:
			GameManager.gold_counter += int(node.gold_amout);
			node.queue_free();

func voltar_player_ao_inicio():
	var player = GameManager.player;
	if not player or not is_instance_valid(player): return
	player.global_position = player_inicio;
	player.velocity = Vector2.ZERO;

#LOJA (jogo pausado enquanto estiver aberta)
func abrir_loja():
	GameManager.na_loja = true;
	Sfx.play("ui_confirm");
	if shop_scene:
		var shop = shop_scene.instantiate();
		get_tree().current_scene.add_child(shop);
		shop.fechou.connect(comecar_proxima_fase);
		shop.abrir(GameManager.fase_atual, tempo_loja);
	get_tree().paused = true;

func comecar_proxima_fase():
	GameManager.fase_atual += 1;
	GameManager.na_loja = false;
	tempo_restante = duracao_da_fase(GameManager.fase_atual);
	get_tree().paused = false;
	#O clique no botão da loja não deve virar um ataque
	Input.action_release("attack_1");
