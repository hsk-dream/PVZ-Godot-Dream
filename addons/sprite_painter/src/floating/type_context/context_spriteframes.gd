@tool
extends Node

@export var label : NodePath
@export var frame_data_textbox : NodePath

var plugin_root
var editor_dock
var anim_list
var frame_list

var edited_object
var current_anim
var current_frame


func connect_plugin(plugin_root_node):
	plugin_root = plugin_root_node


func try_edit(object):
	get_node(label).hide()
	get_node(frame_data_textbox).hide()
	if object is AnimatedSprite2D || object is AnimatedSprite3D:
		try_edit(object.frames)
		return

	if object is SpriteFrames:
		edited_object = object
		call_deferred("update_spriteframes")


func try_connect_bottom_dock(dock : Control):
	if dock.get_class() == "SpriteFramesEditor":
		editor_dock = dock
		anim_list = dock.get_child(0).get_child(1).get_child(0).get_child(1)
		anim_list\
			.item_selected.connect(_on_anim_selected)
		frame_list = dock.get_child(1).get_child(1).get_child(0).get_child(1)
		frame_list\
			.item_clicked.connect(_on_frame_selected)


func update_spriteframes():
	current_anim = anim_list.get_selected().get_text(0)
	current_frame = frame_list.get_selected_items()[0]
	get_node(label).show()
	get_node(frame_data_textbox).show()
	get_node(frame_data_textbox).text = "%s : frame %s" % [current_anim, current_frame]

	var frame_tex = edited_object.get_frame(current_anim, current_frame)
	if frame_tex is AtlasTexture:
		plugin_root.edit_subresource(
			frame_tex.atlas.resource_path,
			frame_tex.region.size,
			frame_tex.region.position,
			true
		)

	else:
		plugin_root.edit_file(frame_tex.resource_path)


func _on_frame_selected(index, at_pos, mouse_button_index):
	update_spriteframes()


func _on_anim_selected():
	update_spriteframes()
