extends Node2D

var speed = 100.0

# func _ready():
# 	$MultiplayerSynchronizer.set_multiplayer_authority(str(name).to_int())

func _enter_tree():
	set_multiplayer_authority(name.to_int())

func _process(delta):
	if is_multiplayer_authority():
		var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down").normalized()
		position += input_dir * speed * delta
