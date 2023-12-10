extends Control

func _ready():
	($Button as Button).pressed.connect(_on_button_pressed)
	
func _on_button_pressed():
	var request = Rivet.POST("matchmaker/lobbies/find", {"game_modes": ["default"]}).request()
	var response = await request.wait_completed()
	
	print(response.body)
