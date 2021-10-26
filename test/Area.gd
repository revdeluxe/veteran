extends Area

func _on_DeathBlock_area_entered(area):
	get_tree().reload_current_scene()
