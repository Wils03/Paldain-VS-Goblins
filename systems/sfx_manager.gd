extends Node

#Efeitos sonoros (autoload "Sfx"). Uso: Sfx.play("sword_swing")
#
#Procura o arquivo pelo nome, com extensão .wav, .ogg ou .mp3, nas pastas abaixo.
#Variações são sorteadas: sword_swing_1.wav, sword_swing_2.wav, ...
#Se o arquivo ainda não existir, não toca nada (sem erro).
#
#CATEGORIA (canal de volume) de cada som:
# 1. a categoria escrita na tabela SOUNDS, se o som estiver nela;
# 2. senão, a pasta onde o arquivo está (FOLDERS).

const SFX_DIR = "res://Audio/sfx/";
#Pasta -> categoria. Coloque o arquivo na pasta certa e ele já usa o volume certo
const FOLDERS = {
	"res://Audio/sfx/": "SFX",
	"res://Audio/ambient/": "Ambient",
	"res://Audio/dialogue/": "Dialogue",
};
const EXTENSIONS = ["wav", "ogg", "mp3"];
const MAX_VARIATIONS = 9;

#Volume geral dos efeitos (dB)
@export var volume_db: float = -4.0;
#Quantos sons podem tocar ao mesmo tempo
@export var max_voices: int = 12;
#Variação aleatória de altura (0.1 = ±10%)
@export var pitch_variation: float = 0.08;

#Sons usados no jogo: nome -> [descrição, categoria]
#Categorias: "SFX" (efeitos), "Ambient" (ambiente), "Dialogue" (diálogo)
const SOUNDS = {
	"sword_swing": ["ataque da espada", "SFX"],
	"sword_hit": ["espada acerta inimigo", "SFX"],
	"player_hurt": ["player recebe dano", "SFX"],
	"player_death": ["player morre", "SFX"],
	"goblin_death": ["goblin morre", "SFX"],
	"sheep_death": ["ovelha morre", "SFX"],
	"dynamite_fuse": ["goblin TNT arremessa a dinamite", "SFX"],
	"explosion": ["dinamite explode", "SFX"],
	"house_hit": ["casa dos goblins leva dano", "SFX"],
	"house_destroyed": ["casa dos goblins destruída", "SFX"],
	"house_repaired": ["casa dos goblins consertada", "SFX"],
	"ritual_cast": ["ritual sagrado (tecla Q)", "SFX"],
	"gold_pickup": ["pegar ouro", "SFX"],
	"meat_pickup": ["pegar bife (cura)", "SFX"],
	"ui_click": ["clique em botão", "SFX"],
	"ui_confirm": ["confirmar / começar o jogo", "SFX"],
	"shield_up": ["pegar a poção de escudo", "SFX"],
	"shield_hit": ["escudo absorve um golpe", "SFX"],
	"shield_break": ["escudo quebra", "SFX"],
};

#nome -> {"streams": [...], "bus": "SFX"}
var cache: Dictionary = {};
var voices: Array[AudioStreamPlayer] = [];
var next_voice: int = 0;

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS;
	create_voices();

func create_voices():
	if not voices.is_empty(): return
	for i in max_voices:
		var voice = AudioStreamPlayer.new();
		voice.bus = Settings.BUS_SFX;
		add_child(voice);
		voices.append(voice);

func play(sound_name: String, volume_offset_db: float = 0.0):
	var entry = get_entry(sound_name);
	var streams: Array = entry.streams;
	if streams.is_empty(): return
	#Garante os canais mesmo se alguém tocar um som antes do _ready
	create_voices();

	#Usa uma voz livre; se todas estiverem ocupadas, reaproveita a mais antiga
	var voice = get_free_voice();
	voice.bus = entry.bus;
	voice.stream = streams.pick_random();
	voice.volume_db = volume_db + volume_offset_db;
	voice.pitch_scale = 1.0 + randf_range(-pitch_variation, pitch_variation);
	voice.play();

func get_free_voice() -> AudioStreamPlayer:
	for voice in voices:
		if not voice.playing:
			return voice;
	var voice = voices[next_voice];
	next_voice = (next_voice + 1) % voices.size();
	return voice;

func get_streams(sound_name: String) -> Array:
	return get_entry(sound_name).streams;

#Categoria (canal de volume) em que o som toca
func get_category(sound_name: String) -> String:
	return get_entry(sound_name).bus;

func get_entry(sound_name: String) -> Dictionary:
	if cache.has(sound_name):
		return cache[sound_name];
	var streams = [];
	var found_bus = "";
	for file_name in [sound_name] + range(1, MAX_VARIATIONS + 1).map(func(i): return "%s_%d" % [sound_name, i]):
		var found = find_stream(file_name);
		if found.is_empty(): continue
		streams.append(found.stream);
		if found_bus == "": found_bus = found.bus;

	#A tabela SOUNDS tem prioridade; senão vale a pasta do arquivo
	var bus = Settings.BUS_SFX;
	if SOUNDS.has(sound_name):
		bus = SOUNDS[sound_name][1];
	elif found_bus != "":
		bus = found_bus;

	cache[sound_name] = {"streams": streams, "bus": bus};
	return cache[sound_name];

func find_stream(file_name: String) -> Dictionary:
	for folder in FOLDERS:
		for extension in EXTENSIONS:
			var path = folder + file_name + "." + extension;
			if ResourceLoader.exists(path):
				return {"stream": load(path), "bus": FOLDERS[folder]};
	return {};
