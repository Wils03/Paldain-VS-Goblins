extends CanvasLayer

#Menu de pausa: ESC pausa/continua o jogo

const MENU_SCENE = "res://UI/main_menu.tscn";

@onready var continue_button: Button = %ContinueButton
@onready var menu_button: Button = %MenuButton
@onready var controls_button: Button = %ControlsButton

func _ready():
	add_to_group("pause_menu");
	#Precisa funcionar com o jogo pausado
	process_mode = Node.PROCESS_MODE_ALWAYS;
	visible = false;
	continue_button.pressed.connect(resume);
	menu_button.pressed.connect(go_to_menu);
	controls_button.pressed.connect(show_controls);

func _unhandled_input(event):
	if not event.is_action_pressed("ui_cancel"): return
	#Na loja o jogo já está pausado: o ESC não deve despausar
	if GameManager.na_loja: return
	#Com a tela de comandos aberta, o ESC é dela
	var controls = get_tree().get_first_node_in_group("controls_screen");
	if controls and controls.visible: return
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

func show_controls():
	Sfx.play("ui_click");
	var controls = get_tree().get_first_node_in_group("controls_screen");
	if controls: controls.abrir(true);

func go_to_menu():
	Sfx.play("ui_confirm");
	get_tree().paused = false;
	GameManager.reset();
	get_tree().change_scene_to_file(MENU_SCENE);
