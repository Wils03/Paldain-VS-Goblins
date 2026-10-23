extends CanvasLayer

#LOJA entre as fases: o paladino no centro e um cartão por upgrade, ligado à
#parte do corpo (capacete = ritual, espada = ataque, peito = vida, botas = velocidade).
#O layout é editável na cena (UI/shop_ui.tscn); este script só preenche os valores.

signal fechou

const COR_NIVEL = Color(0.93, 0.7, 0.16);
const COR_VAZIO = Color(0.47, 0.38, 0.26);

@onready var title: Label = %Title
@onready var subtitle: Label = %Subtitle
@onready var gold_label: Label = %GoldLabel
@onready var timer_label: Label = %TimerLabel
@onready var next_button: Button = %NextButton
@onready var cards: Control = %Cards

var tempo: float = 45.0;
var upgrades: Node;
var fechada: bool = false;

func _ready():
	#Funciona com o jogo pausado
	process_mode = Node.PROCESS_MODE_ALWAYS;
	next_button.pressed.connect(fechar);
	next_button.mouse_entered.connect(Sfx.play.bind("ui_click", -10.0));
	for id in PlayerUpgrades.ORDEM:
		var button: Button = card(id).get_node("BuyButton");
		button.pressed.connect(comprar.bind(id));
		button.mouse_entered.connect(Sfx.play.bind("ui_click", -10.0));

func abrir(fase: int, tempo_loja: float):
	title.text = "FASE %d CONCLUÍDA!" % fase;
	subtitle.text = "Equipe o paladino para a fase %d" % (fase + 1);
	tempo = tempo_loja;
	if GameManager.player and is_instance_valid(GameManager.player):
		upgrades = GameManager.player.get_node_or_null("Upgrades");
	atualizar();
	next_button.grab_focus();

func _process(delta):
	if fechada: return
	tempo -= delta;
	var segundos = maxi(ceili(tempo), 0);
	timer_label.text = "Próxima fase em %d:%02d" % [segundos / 60, segundos % 60];
	gold_label.text = str(GameManager.gold_counter);
	if tempo <= 0.0:
		fechar();

func card(id: String) -> Control:
	return cards.get_node("Card_" + id);

#Atualiza ouro, níveis, valores atuais e botões de compra
func atualizar():
	gold_label.text = str(GameManager.gold_counter);
	if not upgrades: return
	for id in PlayerUpgrades.ORDEM:
		var c = card(id);
		var nivel = upgrades.nivel(id);
		c.get_node("Plus").text = "+%d" % nivel;
		c.get_node("Atual").text = "atual: %s" % upgrades.valor_atual(id);
		var pips = c.get_node("Pips").get_children();
		for i in pips.size():
			pips[i].color = COR_NIVEL if i < nivel else COR_VAZIO;
		var button: Button = c.get_node("BuyButton");
		if upgrades.no_maximo(id):
			button.text = "MÁX";
			button.disabled = true;
		else:
			button.text = str(upgrades.preco(id));
			button.disabled = not upgrades.pode_comprar(id);

func comprar(id: String):
	if upgrades and upgrades.comprar(id):
		Sfx.play("gold_pickup");
	else:
		Sfx.play("ui_click");
	atualizar();

#Fecha a loja (botão "Próxima fase" ou fim do tempo)
func fechar():
	if fechada: return
	fechada = true;
	Sfx.play("ui_confirm");
	fechou.emit();
	queue_free();
