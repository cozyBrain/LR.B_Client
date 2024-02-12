extends PanelContainer

signal play_space(space_name)

func _on_play_the_space_pressed():
	emit_signal("play_space", %description.text)
