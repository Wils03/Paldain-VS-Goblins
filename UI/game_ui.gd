extends CanvasLayer

@onready var timer_label = %TimerLabel
@onready var gold_label = %GoldLabel 

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	#UPDATE LABELS
	timer_label.text = GameManager.time_elapsed_string
	gold_label.text = str(GameManager.gold_counter, " Gold")
	
