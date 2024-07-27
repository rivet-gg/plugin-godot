extends HBoxContainer

func _open_url(url: String):
	OS.shell_open(url)
