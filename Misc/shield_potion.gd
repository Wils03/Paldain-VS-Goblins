extends Node2D

#POÇÃO DE ESCUDO (dropada só pelos goblins): ao pegar, o player ganha escudo,
#que absorve dano antes da vida (veja Player/player_shield.gd).

#Quanto de escudo a poção dá
@export var escudo: float = 25.0;

@onready var area: Area2D = $Area2D
@onready var sprite: Sprite2D = $Sprite2D

var tempo: float = 0.0;
var sprite_y: float;
var flutuando: bool = false;

func _ready():
	area.body_entered.connect(on_body_entered);
	sprite_y = sprite.position.y;
	#Sem animação de drop (colocada direto na cena): já começa flutuando
	if not has_meta(SpawnUtils.DROP_IN_AIR):
		flutuando = true;

func _process(delta):
	#Depois de pousar, flutua de leve no chão para chamar atenção
	if not flutuando: return
	tempo += delta;
	sprite.position.y = sprite_y + sin(tempo * 3.0) * 3.0;

#Chamado pela animação de drop ao tocar o chão: quique igual ao do ouro
#(amassa, salta duas vezes e assenta), depois começa a flutuar
func animar_pouso():
	SpawnUtils.quicar_sprite(sprite, sprite_y, func(): flutuando = true);

func on_body_entered(body: Node2D):
	#Ainda voando (animação de drop): não pode ser coletada
	if has_meta(SpawnUtils.DROP_IN_AIR): return
	if not body.is_in_group("player"): return
	var shield = body.get_node_or_null("Escudo");
	if shield:
		shield.adicionar(escudo);
	queue_free();
