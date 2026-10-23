extends Node

#Gerencia a música do jogo (autoload "MusicManager"), com transição suave entre faixas:
# - gameplay: alterna entre as variações do loop principal
# - onda intensa: quando há muitos inimigos vivos
# - game over: ao morrer

const GAMEPLAY_TRACKS = ["res://Audio/music/gameplay_loop_1.mp3", "res://Audio/music/gameplay_loop_2.mp3"];
const INTENSE_TRACK = "res://Audio/music/wave_intense.mp3";
const GAME_OVER_TRACK = "res://Audio/music/game_over.mp3";
const TITLE_TRACK = "res://Audio/music/title_theme.mp3";
#Cena do menu: enquanto ela estiver aberta toca o tema do menu
const MENU_SCENE = "res://UI/main_menu.tscn";

#Volume da música (dB). -80 = mudo
@export var volume_db: float = -10.0;
#Duração da transição entre faixas (segundos)
@export var fade_time: float = 1.5;
#Inimigos vivos para entrar na música intensa
@export var intense_enter_enemies: int = 25;
#Inimigos vivos para voltar ao loop normal
@export var intense_exit_enemies: int = 15;
#Tempo mínimo numa faixa antes de trocar (evita ficar alternando)
@export var min_track_time: float = 20.0;

enum State { NONE, TITLE, GAMEPLAY, INTENSE, GAME_OVER }

const SILENT_DB = -80.0;

var state: State = State.NONE;
var players: Array[AudioStreamPlayer] = [];
var current: int = 0;
var gameplay_index: int = 0;
var state_time: float = 0.0;

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS;
	for i in 2:
		var player = AudioStreamPlayer.new();
		player.bus = Settings.BUS_MUSIC;
		player.volume_db = SILENT_DB;
		player.finished.connect(on_track_finished.bind(player));
		add_child(player);
		players.append(player);

func _process(delta):
	state_time += delta;
	var scene = get_tree().current_scene;
	if scene == null: return

	#MENU
	if scene.scene_file_path == MENU_SCENE:
		if state != State.TITLE:
			change_to(State.TITLE);
		return

	#GAME OVER
	if GameManager.is_game_over:
		if state != State.GAME_OVER:
			change_to(State.GAME_OVER);
		return

	#Início da partida ou reinício depois do game over
	if state == State.NONE or state == State.GAME_OVER or state == State.TITLE:
		change_to(State.GAMEPLAY);
		return

	#ONDA INTENSA conforme a quantidade de inimigos vivos
	if state_time < min_track_time: return
	var enemies = get_tree().get_nodes_in_group("enemies").size();
	if state == State.GAMEPLAY and enemies >= intense_enter_enemies:
		change_to(State.INTENSE);
	elif state == State.INTENSE and enemies < intense_exit_enemies:
		change_to(State.GAMEPLAY);

func change_to(new_state: State):
	state = new_state;
	state_time = 0.0;
	match new_state:
		State.TITLE:
			crossfade(TITLE_TRACK, true);
		State.GAMEPLAY:
			crossfade(next_gameplay_track(), false);
		State.INTENSE:
			crossfade(INTENSE_TRACK, true);
		State.GAME_OVER:
			crossfade(GAME_OVER_TRACK, false);

func next_gameplay_track() -> String:
	var track = GAMEPLAY_TRACKS[gameplay_index % GAMEPLAY_TRACKS.size()];
	gameplay_index += 1;
	return track;

#Quando uma variação do loop principal termina, entra a próxima
func on_track_finished(player: AudioStreamPlayer):
	if player != players[current]: return
	if state == State.GAMEPLAY:
		crossfade(next_gameplay_track(), false);

func crossfade(path: String, loop: bool):
	var stream = load(path);
	if stream == null: return
	if "loop" in stream:
		stream.loop = loop;

	var old_player = players[current];
	current = 1 - current;
	var new_player = players[current];

	new_player.stream = stream;
	new_player.volume_db = SILENT_DB;
	new_player.play();

	var tween = create_tween().set_parallel(true);
	tween.tween_property(new_player, "volume_db", volume_db, fade_time);
	if old_player.playing:
		tween.tween_property(old_player, "volume_db", SILENT_DB, fade_time);
		tween.chain().tween_callback(old_player.stop);
