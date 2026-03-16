@tool
extends MarginContainer

@onready var type_handlers = $"TypeHandlers".get_children()
@onready var cursor_pos_info = $"Container/Box/CursorPos"

var editor_plugin : EditorPlugin
var plugin_root : Node

var input_start := Vector2()
var input_end := Vector2()
var input_pressed := false

var edited_object : Object


func _ready():
	hide()
	readjust_size()
	show()

	plugin_root = self
	while !plugin_root is Window:
		plugin_root = plugin_root.get_parent()
		if !plugin_root is SpritePainterRoot:
			continue

		editor_plugin = plugin_root.editor_plugin
		plugin_root.object_selected.connect(_on_plugin_object_selected)
		for x in type_handlers:
			x.connect_plugin(plugin_root)
			break

	var c = Control.new()
	editor_plugin.add_control_to_bottom_panel(c, "AAA")

	for x in c.get_parent().get_children():
		for y in type_handlers:
			y.try_connect_bottom_dock(x)

	editor_plugin.remove_control_from_bottom_panel(c)
	_on_plugin_object_selected(plugin_root.edited_object)


func handle_image_input(event):
	if event is InputEventMouseMotion:
		if input_pressed:
			input_end = event.position.floor()
		
		else:
			input_start = event.position.floor()

	elif event is InputEventMouseButton:
		input_pressed = event.pressed
		input_end = event.position.floor()
	
	if input_pressed:
		cursor_pos_info.text = "Cursor: %s -> %s (size %s)" % [
			input_start,
			input_end,
			(input_end - input_start).abs() + Vector2.ONE
		]

	else:
		cursor_pos_info.text = "Cursor: %s" % input_start

	return false


func _on_plugin_object_selected(obj):
	if obj == null: return
	for x in type_handlers:
		x.try_edit(obj)

	edited_object = obj
	readjust_size()


func readjust_size():
	size = Vector2.ZERO
	position = Vector2(get_parent().size) - get_minimum_size() #get_parent().size can be a Vector2i


func _on_visibility_changed():
	pass
