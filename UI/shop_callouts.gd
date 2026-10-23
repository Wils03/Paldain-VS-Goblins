@tool
extends Control

#Linhas da loja que ligam uma parte do paladino ao cartão do upgrade.
#"linhas" guarda pares de pontos: [ponto no paladino, ponto no cartão, ...].
#Aparece também no editor; ajuste os pontos pelo Inspector.

@export var linhas: PackedVector2Array = []:
	set(value):
		linhas = value;
		queue_redraw();

@export var cor_linha: Color = Color(1.0, 0.886, 0.47);
@export var cor_contorno: Color = Color(0.18, 0.118, 0.07);

func _draw():
	for i in range(0, linhas.size() - 1, 2):
		var paladino = linhas[i];
		var cartao = linhas[i + 1];
		draw_line(paladino, cartao, cor_contorno, 6.0, true);
		draw_line(paladino, cartao, cor_linha, 3.0, true);
		#Ponto na parte do corpo
		draw_circle(paladino, 9.0, cor_contorno);
		draw_circle(paladino, 6.0, Color(1.0, 0.84, 0.31));
