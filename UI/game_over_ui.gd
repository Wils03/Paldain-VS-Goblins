class_name GameOverUI
extends CanvasLayer

const MENU_SCENE = "res://UI/main_menu.tscn";

@onready var time_label: Label = %TimeLabel
@onready var monster_label: Label = %MonsterLabel
@onready var retry_button: Button = %RetryButton
@onready var menu_button: Button = %MenuButton

# Called when the node enters the scene tree for the first time.
func _ready():
	time_label.text = GameManager.time_elapsed_string;
	monster_label.text = str(GameManager.monsters_defeated_counter);
	retry_button.pressed.connect(restart_game);
	menu_button.pressed.connect(go_to_menu);
	retry_button.grab_focus();

#TENTAR NOVAMENTE
func restart_game():
	Sfx.play("ui_confirm");
	GameManager.reset();
	get_tree().reload_current_scene();

#VOLTAR AO MENU PRINCIPAL
func go_to_menu():
	Sfx.play("ui_click");
	GameManager.reset();
	get_tree().change_scene_to_file(MENU_SCENE);
