@tool
extends Button

@export var icon_name := "Node"
	# set(v):
	# 	_set_icon_name(v)


func _set_icon_name(v):
	icon_name = v
	if has_theme_icon(v, "EditorIcons"):
		icon = get_theme_icon(v, "EditorIcons")


func _ready():
	_set_icon_name(icon_name)
