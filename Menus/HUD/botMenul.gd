extends Panel


func _ready():
	$VBoxContainer/add_bot_ct.disabled = false
	$VBoxContainer/add_bot_t.disabled = false
	MenuManager.connect("back_pressed", self,"_on_back_pressed")


func _on_add_bot_pressed():
	MusicMan.click()
	var lvl = get_tree().get_nodes_in_group("Level")[0]
	lvl.spawnBot()


func _on_add_bot_ct_pressed():
	MusicMan.click()
	var lvl = get_tree().get_nodes_in_group("Level")[0]
	lvl.spawnBot(1)
	

func _on_add_bot_t_pressed():
	MusicMan.click()
	var lvl = get_tree().get_nodes_in_group("Level")[0]
	lvl.spawnBot(0)


func _on_back_pressed():
	queue_free()
