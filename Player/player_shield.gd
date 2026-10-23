class_name PlayerShield
extends Node2D

#ESCUDO do player (nó "Escudo" dentro do Player): absorve o dano antes da vida.
#Ganho com a poção azul dos goblins; dura até ser gasto.
#Mostra uma bolha azul em volta do paladino e uma barra azul sobre a barra de vida.

#Máximo de escudo acumulado
@export var maximo: float = 50.0;

@export_category("Visual (coordenadas locais do Player)")
@export var centro_bolha: Vector2 = Vector2(0, -80);
@export var raio_bolha: float = 150.0;
#Barra logo acima da barra de vida
@export var barra: Rect2 = Rect2(-66, 20, 132, 9);

var valor: float = 0.0;
var tempo: float = 0.0;

func adicionar(quantidade: float):
	valor = min(valor + quantidade, maximo);
	Sfx.play("shield_up");
	queue_redraw();

#Recebe o dano e devolve o que sobrou para a vida
func absorver(dano: float) -> float:
	if valor <= 0.0: return dano
	var absorvido = min(valor, dano);
	valor -= absorvido;
	Sfx.play("shield_break" if valor <= 0.0 else "shield_hit");
	queue_redraw();
	return dano - absorvido;

func tem_escudo() -> bool:
	return valor > 0.0;

func _process(delta):
	if valor <= 0.0: return
	tempo += delta;
	queue_redraw();

func _draw():
	if valor <= 0.0: return
	#Bolha pulsando
	var pulso = 0.5 + 0.5 * sin(tempo * 4.0);
	draw_circle(centro_bolha, raio_bolha, Color(0.35, 0.65, 1.0, 0.12 + 0.06 * pulso));
	draw_arc(centro_bolha, raio_bolha, 0.0, TAU, 48, Color(0.6, 0.85, 1.0, 0.55 + 0.25 * pulso), 6.0, true);
	#Barra do escudo
	draw_rect(barra, Color(0.05, 0.08, 0.18, 0.9));
	var cheio = Rect2(barra.position, Vector2(barra.size.x * valor / maximo, barra.size.y));
	draw_rect(cheio, Color(0.3, 0.62, 1.0));
