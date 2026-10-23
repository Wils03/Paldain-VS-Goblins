extends Label

@onready var count_gold: Label = %GoldLabel
# Called every frame. 'delta' is the elapsed time since the previous frame.

func update_gold_label(gold):
	count_gold.text = str(gold) + " Gold";
