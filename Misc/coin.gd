extends "res://Misc/gold.gd"

#MOEDA: vale 1 de ouro (o saco vale 5). Usa a mesma coleta do saco (gold.gd).
#Cai com o mesmo arco do ouro, quica ao pousar e depois fica girando.

@onready var sprite: Sprite2D = $Sprite2D

var tempo: float = 0.0;
var sprite_y: float;
var largura: float;
var girando: bool = false;

func _ready():
	super();
	sprite_y = sprite.position.y;
	largura = sprite.scale.x;
	#Sem animação de drop (colocada direto na cena): já começa girando
	if not has_meta(SpawnUtils.DROP_IN_AIR):
		girando = true;

func _process(delta):
	#Gira (achata e volta) para brilhar no chão
	if not girando: return
	tempo += delta;
	sprite.scale.x = largura * max(absf(cos(tempo * 2.5)), 0.15);

#Chamado pela animação de drop ao tocar o chão
func animar_pouso():
	SpawnUtils.quicar_sprite(sprite, sprite_y, func(): girando = true);
