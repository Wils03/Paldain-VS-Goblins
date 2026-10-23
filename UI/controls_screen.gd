extends CanvasLayer

#Tela de comandos: aparece sozinha na primeira partida (com o jogo pausado)
#e pode ser aberta de novo pelo botão "Comandos" do menu de pausa.

#[teclas, o que faz]
const COMANDOS = [
	["W A S D  /  Setas", "Andar"],
	["Clique esquerdo", "Atacar (na direção em que está andando)"],
	["Q", "Ritual sagrado (quando estiver pronto)"],
	["ESC", "Pausar o jogo"],
];

const DICAS = [
	"Sobreviva até o tempo da fase acabar. Entre as fases abre a loja de upgrades.",
	"Moeda vale 1 de ouro e o saco vale 5. Carne recupera vida.",
	"A poção azul dá um escudo que absorve o dano antes da vida.",
	"Casa de goblin destruída para de soltar inimigos (até o reparador consertar).",
];

const GROUP = "controls_screen";

@onready var rows: GridContainer = %Rows
@onready var tips: VBoxContainer = %Tips
@onready var start_button: Button = %StartButton

#Aberta pelo menu de pausa: ao fechar volta para a pausa em vez de soltar o jogo
var aberta_pela_pausa := false;

func _ready():
	add_to_group(GROUP);
	process_mode = Node.PROCESS_MODE_ALWAYS;
	montar_lista();
	start_button.pressed.connect(fechar);
	visible = false;
	if not Settings.comandos_vistos:
		abrir(false);

func montar_lista():
	for comando in COMANDOS:
		var tecla = PanelContainer.new();
		tecla.add_theme_stylebox_override("panel", estilo_tecla());
		tecla.size_flags_horizontal = Control.SIZE_SHRINK_END;
		var tecla_label = Label.new();
		tecla_label.text = comando[0];
		tecla_label.add_theme_color_override("font_color", Color(1, 0.96, 0.85));
		tecla_label.add_theme_font_size_override("font_size", 20);
		tecla.add_child(tecla_label);
		rows.add_child(tecla);
		var acao = Label.new();
		acao.text = comando[1];
		acao.add_theme_font_size_override("font_size", 22);
		rows.add_child(acao);
	for dica in DICAS:
		var label = Label.new();
		label.text = "• " + dica;
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART;
		label.custom_minimum_size.x = 620;
		label.add_theme_font_size_override("font_size", 16);
		tips.add_child(label);

func estilo_tecla() -> StyleBoxFlat:
	var estilo = StyleBoxFlat.new();
	estilo.bg_color = Color(0.32, 0.22, 0.14);
	estilo.border_color = Color(0.16, 0.1, 0.05);
	estilo.set_border_width_all(2);
	estilo.border_width_bottom = 5;
	estilo.set_corner_radius_all(6);
	estilo.content_margin_left = 12; estilo.content_margin_right = 12;
	estilo.content_margin_top = 2; estilo.content_margin_bottom = 4;
	return estilo;

func abrir(pela_pausa: bool):
	aberta_pela_pausa = pela_pausa;
	start_button.text = "Voltar" if pela_pausa else "Começar";
	visible = true;
	get_tree().paused = true;
	start_button.grab_focus();

func fechar():
	Sfx.play("ui_confirm");
	visible = false;
	if not Settings.comandos_vistos:
		Settings.comandos_vistos = true;
		Settings.save_settings();
	if aberta_pela_pausa:
		var pause_menu = get_tree().get_first_node_in_group("pause_menu");
		if pause_menu: pause_menu.continue_button.grab_focus();
	else:
		get_tree().paused = false;
		#O clique no botão não deve virar um ataque ao começar
		Input.action_release("attack_1");

func _unhandled_input(event):
	if not visible: return
	#ESC também fecha a tela (e começa o jogo na primeira vez)
	if event.is_action_pressed("ui_cancel"):
		fechar();
		get_viewport().set_input_as_handled();
