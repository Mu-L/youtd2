extends Label


# Called when the node enters the scene tree for the first time.
func _ready():
	text = "Version: %s" % Config.build_version()
