extends Node

#Configurações do jogador (autoload "Settings"): volumes salvos em user://settings.cfg
#
#Cada categoria de som tem um canal de áudio (bus) próprio no AudioServer.
#Para mudar a categoria de um efeito, veja a tabela SOUNDS em systems/sfx_manager.gd.

const SAVE_PATH = "user://settings.cfg";

const BUS_MASTER = "Master";
const BUS_MUSIC = "Music";
const BUS_SFX = "SFX";
const BUS_AMBIENT = "Ambient";
const BUS_DIALOGUE = "Dialogue";

#Ordem e nomes mostrados no painel de volume
const CATEGORIES = [
	[BUS_MASTER, "Geral"],
	[BUS_MUSIC, "Música"],
	[BUS_SFX, "Efeitos"],
	[BUS_AMBIENT, "Ambiente"],
	[BUS_DIALOGUE, "Diálogo"],
];

#Volumes de 0.0 a 1.0
var volumes: Dictionary = {
	BUS_MASTER: 1.0,
	BUS_MUSIC: 0.8,
	BUS_SFX: 0.9,
	BUS_AMBIENT: 0.8,
	BUS_DIALOGUE: 1.0,
};

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS;
	for category in CATEGORIES:
		if category[0] != BUS_MASTER:
			create_bus(category[0]);
	load_settings();
	for bus in volumes:
		apply_volume(bus);

func create_bus(bus_name: String):
	if AudioServer.get_bus_index(bus_name) != -1: return
	AudioServer.add_bus();
	var index = AudioServer.bus_count - 1;
	AudioServer.set_bus_name(index, bus_name);
	AudioServer.set_bus_send(index, BUS_MASTER);

func get_volume(bus_name: String) -> float:
	return volumes.get(bus_name, 1.0);

func set_volume(bus_name: String, value: float):
	volumes[bus_name] = clamp(value, 0.0, 1.0);
	apply_volume(bus_name);

func apply_volume(bus_name: String):
	var index = AudioServer.get_bus_index(bus_name);
	if index == -1: return
	var value = volumes[bus_name];
	AudioServer.set_bus_volume_db(index, linear_to_db(max(value, 0.0001)));
	AudioServer.set_bus_mute(index, value <= 0.001);

func save_settings():
	var config = ConfigFile.new();
	for bus in volumes:
		config.set_value("audio", bus, volumes[bus]);
	config.save(SAVE_PATH);

func load_settings():
	var config = ConfigFile.new();
	if config.load(SAVE_PATH) != OK: return
	for bus in volumes:
		volumes[bus] = float(config.get_value("audio", bus, volumes[bus]));
