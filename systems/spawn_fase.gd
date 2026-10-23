class_name SpawnFase
extends Resource

#Uma fase da progressão do MobSpawner: a partir de um minuto da partida,
#quantas criaturas de cada tipo podem estar vivas ao mesmo tempo.

#Minuto da partida em que esta fase começa
@export var a_partir_do_minuto: float = 0.0;
#Máximo total de criaturas vivas do spawner nesta fase (0 = soma das cotas)
@export var maximo: int = 10;
#Cota de cada criatura: cena -> quantidade máxima viva ao mesmo tempo
@export var cotas: Dictionary[PackedScene, int] = {};

func limite_total() -> int:
	if maximo > 0: return maximo
	var total = 0;
	for scene in cotas:
		total += cotas[scene];
	return total;
