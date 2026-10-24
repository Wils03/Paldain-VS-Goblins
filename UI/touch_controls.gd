extends CanvasLayer

#Controles de toque (versão celular):
# - joystick: toque e arraste em qualquer lugar da metade esquerda da tela
# - botão da espada: ataca (segurando, continua atacando)
# - botão da estrela: ritual sagrado (mostra a recarga)
# - botão de pausa (e o botão "voltar" do Android)
#Eles acionam as mesmas ações do teclado (move_*, attack_1, sacred_spell),
#então o player funciona igual no PC e no celular.

const STICK_RAIO = 80.0;
const STICK_ZONA_MORTA = 0.25;
const ATAQUE_RAIO = 72.0;
const RITUAL_RAIO = 50.0;
const PAUSA_TAMANHO = 52.0;
const REPETIR_ATAQUE = 0.12;

var icone_espada: Texture2D = load("res://Addons/Tiny Swords/UI/Icons Loja/sword.png");
var icone_ritual: Texture2D = load("res://UI/icons/magic_star.png");

var tela: Control;
#Toques em andamento: índice do dedo -> o que ele está fazendo
var dedo_stick := -1;
var dedo_ataque := -1;
var dedo_ritual := -1;
var stick_base := Vector2.ZERO;
var stick_ponta := Vector2.ZERO;
var tempo_ataque := 0.0;

func _ready():
	layer = 15;
	process_mode = Node.PROCESS_MODE_ALWAYS;
	#Roda antes do player no quadro, para ele ver o "apertou agora" do ataque repetido
	process_priority = -10;
	tela = Control.new();
	tela.set_anchors_preset(Control.PRESET_FULL_RECT);
	#Não bloqueia os cliques/toques dos menus
	tela.mouse_filter = Control.MOUSE_FILTER_IGNORE;
	tela.draw.connect(desenhar);
	add_child(tela);

func em_jogo() -> bool:
	return not get_tree().paused and not GameManager.is_game_over and GameManager.player != null;

func tamanho() -> Vector2:
	return tela.get_viewport_rect().size;

func centro_ataque() -> Vector2:
	var t = tamanho();
	return Vector2(t.x - 120, t.y - 115);

func centro_ritual() -> Vector2:
	return centro_ataque() + Vector2(-150, 35);

func retangulo_pausa() -> Rect2:
	#Ao lado do painel do ritual, no canto de cima
	return Rect2(Vector2(158, 14), Vector2(PAUSA_TAMANHO, PAUSA_TAMANHO));

func _process(delta):
	var ativo = em_jogo();
	if visible != ativo:
		visible = ativo;
		if not ativo: soltar_tudo();
	if not ativo: return
	#Segurando a espada: ataca de novo assim que o golpe anterior termina
	if dedo_ataque != -1:
		tempo_ataque -= delta;
		if tempo_ataque <= 0.0 and not GameManager.player.is_attacking:
			apertar_ataque();
	tela.queue_redraw();

func _input(event):
	if not (event is InputEventScreenTouch or event is InputEventScreenDrag): return
	if not visible: return
	var pos = event.position;
	if event is InputEventScreenTouch and event.pressed:
		if retangulo_pausa().grow(10).has_point(pos):
			pausar();
		elif pos.distance_to(centro_ataque()) <= ATAQUE_RAIO + 14:
			dedo_ataque = event.index;
			apertar_ataque();
		elif pos.distance_to(centro_ritual()) <= RITUAL_RAIO + 14:
			dedo_ritual = event.index;
			Input.action_press("sacred_spell");
		elif pos.x < tamanho().x * 0.5 and dedo_stick == -1:
			dedo_stick = event.index;
			stick_base = pos;
			stick_ponta = pos;
		else:
			return
		get_viewport().set_input_as_handled();
	elif event is InputEventScreenTouch:
		if event.index == dedo_stick:
			dedo_stick = -1;
			aplicar_direcao(Vector2.ZERO);
		elif event.index == dedo_ataque:
			dedo_ataque = -1;
			Input.action_release("attack_1");
		elif event.index == dedo_ritual:
			dedo_ritual = -1;
			Input.action_release("sacred_spell");
	elif event is InputEventScreenDrag and event.index == dedo_stick:
		var deslocamento = (pos - stick_base).limit_length(STICK_RAIO);
		stick_ponta = stick_base + deslocamento;
		aplicar_direcao(deslocamento / STICK_RAIO);
		get_viewport().set_input_as_handled();

func apertar_ataque():
	#Solta e aperta de novo para contar como um novo "apertou agora"
	Input.action_release("attack_1");
	Input.action_press("attack_1");
	tempo_ataque = REPETIR_ATAQUE;

#O joystick funciona em 8 direções, igual às teclas, para os ataques
#para cima/baixo continuarem saindo como no teclado
func aplicar_direcao(vetor: Vector2):
	var dir = Vector2.ZERO;
	if vetor.length() >= STICK_ZONA_MORTA:
		var angulo = snappedf(vetor.angle(), PI / 4.0);
		dir = Vector2.from_angle(angulo).round();
	acao("move_right", dir.x > 0);
	acao("move_left", dir.x < 0);
	acao("move_down", dir.y > 0);
	acao("move_up", dir.y < 0);

func acao(nome: String, apertada: bool):
	if apertada: Input.action_press(nome);
	else: Input.action_release(nome);

func soltar_tudo():
	dedo_stick = -1; dedo_ataque = -1; dedo_ritual = -1;
	aplicar_direcao(Vector2.ZERO);
	Input.action_release("attack_1");
	Input.action_release("sacred_spell");

func pausar():
	soltar_tudo();
	var pause_menu = get_tree().get_first_node_in_group("pause_menu");
	if pause_menu: pause_menu.pause();

func desenhar():
	var fonte = ThemeDB.fallback_font;
	#Joystick: só aparece enquanto o dedo está na tela
	if dedo_stick != -1:
		tela.draw_circle(stick_base, STICK_RAIO, Color(1, 1, 1, 0.12));
		tela.draw_arc(stick_base, STICK_RAIO, 0, TAU, 48, Color(1, 1, 1, 0.45), 3.0, true);
		tela.draw_circle(stick_ponta, STICK_RAIO * 0.42, Color(1, 1, 1, 0.5));
	#Botão de ataque
	var ca = centro_ataque();
	var cor_ataque = Color(0.75, 0.2, 0.15, 0.75) if dedo_ataque != -1 else Color(0.55, 0.12, 0.1, 0.55);
	tela.draw_circle(ca, ATAQUE_RAIO, cor_ataque);
	tela.draw_arc(ca, ATAQUE_RAIO, 0, TAU, 48, Color(1, 0.9, 0.75, 0.8), 3.0, true);
	desenhar_icone(icone_espada, ca, ATAQUE_RAIO * 1.1);
	#Botão do ritual com a recarga em volta
	var cr = centro_ritual();
	var player = GameManager.player;
	var pronto = player != null and player.ritual_cooldown <= 0.0;
	tela.draw_circle(cr, RITUAL_RAIO, Color(0.2, 0.35, 0.75, 0.7) if pronto else Color(0.15, 0.15, 0.2, 0.55));
	if player != null and not pronto and player.ritual_interval > 0:
		var falta = clamp(player.ritual_cooldown / player.ritual_interval, 0.0, 1.0);
		tela.draw_arc(cr, RITUAL_RAIO - 3, -PI / 2, -PI / 2 + TAU * (1.0 - falta), 48, Color(0.55, 0.75, 1, 0.9), 5.0, true);
		desenhar_icone(icone_ritual, cr, RITUAL_RAIO * 1.1, Color(1, 1, 1, 0.35));
		var texto = str(ceili(player.ritual_cooldown));
		tela.draw_string_outline(fonte, cr + Vector2(-30, 9), texto, HORIZONTAL_ALIGNMENT_CENTER, 60, 26, 6, Color(0, 0, 0, 0.8));
		tela.draw_string(fonte, cr + Vector2(-30, 9), texto, HORIZONTAL_ALIGNMENT_CENTER, 60, 26, Color(1, 1, 1));
	else:
		tela.draw_arc(cr, RITUAL_RAIO, 0, TAU, 48, Color(1, 0.95, 0.6, 0.9), 3.0, true);
		desenhar_icone(icone_ritual, cr, RITUAL_RAIO * 1.1);
	#Botão de pausa
	var r = retangulo_pausa();
	tela.draw_rect(r, Color(0, 0, 0, 0.45));
	tela.draw_rect(r, Color(1, 1, 1, 0.7), false, 2.0);
	var barra = Vector2(8, r.size.y * 0.5);
	tela.draw_rect(Rect2(r.get_center() + Vector2(-13, -barra.y / 2), barra), Color(1, 1, 1, 0.9));
	tela.draw_rect(Rect2(r.get_center() + Vector2(5, -barra.y / 2), barra), Color(1, 1, 1, 0.9));

func desenhar_icone(textura: Texture2D, centro: Vector2, lado: float, cor := Color(1, 1, 1, 1)):
	if textura == null: return
	var escala = lado / max(textura.get_width(), textura.get_height());
	var t = Vector2(textura.get_size()) * escala;
	tela.draw_texture_rect(textura, Rect2(centro - t / 2.0, t), false, cor);
