extends Node

@export var mob_spawner: MobSpawner
@export var inicial_spawn_rate: float = 30.0;
@export var spawn_rate_per_minutes:float = 30;
@export var wave_duration: float = 20;
@export var break_intensity: float = 0.5;

var time:float = 0.0

func _process(delta):
	#Iginorar GameOver
	if GameManager.is_game_over: return;
	
	time += delta;
	#Dificuldade liner (linha verde)
	var spawn_rate = inicial_spawn_rate + (spawn_rate_per_minutes * (time / 60.0));
	#Sistema de ondas (linha rosa)
	var sin_wave = sin( wave_duration / ((time/60) * TAU));
	var wave_factor = remap(sin_wave, -1.0 , 1.0, break_intensity, 1);
	
	spawn_rate *= wave_factor;
	
	mob_spawner.mobs_per_minute = spawn_rate;
