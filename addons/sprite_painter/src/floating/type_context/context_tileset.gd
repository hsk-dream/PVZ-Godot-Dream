@tool
extends Node

var plugin_root
var editor_dock
var source_list

var edited_object


func connect_plugin(plugin_root_node):
	plugin_root = plugin_root_node


func try_edit(object):
	if object is TileMap:
		try_edit(object)
		return

	if object is TileSet:
		edited_object = object
		call_deferred("update_tileset")


func try_connect_bottom_dock(dock : Control):
	if dock.get_class() == "TileSetEditor":
		editor_dock = dock
		source_list = dock.get_child(1).get_child(0).get_child(0)
		source_list\
			.item_clicked.connect(_on_source_selected)


func update_tileset():
	var selected_id = source_list.get_selected_items()[0]
	var sauce = edited_object.get_source(selected_id)
	if !(sauce is TileSetAtlasSource):
		return

	plugin_root.edit_subresource(
		sauce.get_texture().resource_path,
		sauce.texture_region_size + sauce.separation,
		sauce.margins,
		false
	)


func _on_source_selected(index, at_pos, mouse_button_index):
	update_tileset()
