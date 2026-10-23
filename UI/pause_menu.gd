extends CanvasLayer

#Menu de pausa: ESC pausa/continua o jogo

const MENU_SCENE = "res://UI/main_menu.tscn";

@onready var continue_button: Button = %ContinueButton
@onready var menu_button: Button = %MenuButton

func _ready():
	#Precisa funcionar com o jogo pausado
	process_mode = Node.PROCESS_MODE_ALWAYS;
	visible = false;
	continue_button.pressed.connect(resume);
	menu_button.pressed.connect(go_to_menu);

func _unhandled_input(event):
	if not event.is_action_pressed("ui_cancel"): return
	if visible:
		resume();
	elif not GameManager.is_game_over:
		pause();
	get_viewport().set_input_as_handled();

func pause():
	visible = true;
	get_tree().paused = true;
	Sfx.play("ui_click");
	continue_button.grab_focus();

func resume():
	Sfx.play("ui_click");
	visible = false;
	get_tree().paused = false;
	#O clique no botão não deve virar um ataque ao voltar
	Input.action_release("attack_1");

func go_to_menu():
	Sfx.play("ui_confirm");
	get_tree().paused = false;
	GameManager.reset();
	get_tree().change_scene_to_file(MENU_SCENE);
