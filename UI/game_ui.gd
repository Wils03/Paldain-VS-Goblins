extends CanvasLayer

@onready var timer_label = %TimerLabel
@onready var gold_label = %GoldLabel
@onready var phase_label = get_node_or_null("%PhaseLabel")
@onready var gold_panel: Control = gold_label.get_parent()
# Tamanho original do painel de ouro; ele só cresce (para a esquerda) quando o texto não cabe
@onready var gold_panel_left: float = gold_panel.offset_left
@onready var gold_label_right: float = gold_label.offset_right

# Alarga o pergaminho do ouro para o número nunca ficar cortado
func ajustar_painel_ouro():
	# get_minimum_size já considera a fonte/LabelSettings que o label usa de verdade
	var largura = gold_label.get_minimum_size().x
	var extra = max(0.0, largura -(gold_label_right - gold_label.offset_left))
	gold_panel.offset_left = gold_panel_left - extra
	gold_label.offset_right = gold_label_right + extra

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	#UPDATE LABELS
	timer_label.text = GameManager.time_elapsed_string
	var gold_text = str(GameManager.gold_counter, " Gold")
	if gold_label.text != gold_text:
		gold_label.text = gold_text
		ajustar_painel_ouro()

	#FASES: o relógio mostra quanto falta para a fase acabar
	var phase = get_tree().get_first_node_in_group(PhaseManager.GROUP)
	if phase:
		timer_label.text = phase.tempo_restante_texto()
		if phase_label:
			var boss = " - BOSS" if phase.eh_fase_de_boss(GameManager.fase_atual) else ""
			phase_label.text = "Fase %d%s" % [GameManager.fase_atual, boss]
	
