extends Control

const GAME_SCENE = "res://main.tscn";

@onready var play_button: Button = %PlayButton
@onready var options_button: Button = %OptionsButton
@onready var quit_button: Button = %QuitButton
@onready var main_buttons: Control = %Buttons
@onready var options_panel: Control = %OptionsPanel
@onready var back_button: Button = %BackButton

func _ready():
	play_button.pressed.connect(on_play_pressed);
	options_button.pressed.connect(show_options.bind(true));
	back_button.pressed.connect(show_options.bind(false));
	quit_button.pressed.connect(on_quit_pressed);
	for button in [play_button, options_button, quit_button, back_button]:
		button.mouse_entered.connect(on_button_hover);
	#Na versão web não existe "sair do jogo"
	quit_button.visible = not OS.has_feature("web");
	options_panel.visible = false;
	play_button.grab_focus();

func _unhandled_input(event):
	#ESC fecha as opções
	if event.is_action_pressed("ui_cancel") and options_panel.visible:
		show_options(false);
		get_viewport().set_input_as_handled();

#CELULAR: botão "voltar" do Android fecha as opções ou sai do jogo
func _notification(what):
	if what != NOTIFICATION_WM_GO_BACK_REQUEST: return
	if options_panel.visible:
		show_options(false);
	else:
		get_tree().quit();

func on_play_pressed():
	Sfx.play("ui_confirm");
	#Zera tempo, ouro e abates antes de começar
	GameManager.reset();
	get_tree().change_scene_to_file(GAME_SCENE);

func show_options(show: bool):
	Sfx.play("ui_click");
	options_panel.visible = show;
	main_buttons.visible = not show;
	if show:
		back_button.grab_focus();
	else:
		options_button.grab_focus();

func on_quit_pressed():
	Sfx.play("ui_click");
	get_tree().quit();

func on_button_hover():
	Sfx.play("ui_click", -10.0);
