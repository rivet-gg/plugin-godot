extends VBoxContainer


func _ready() -> void:
	%CancelButton.pressed.connect(_on_cancel_button_pressed)

func _on_cancel_button_pressed() -> void:
	# TODO(forest): cancel cli command
	owner.change_current_screen(owner.Screen.Login)
