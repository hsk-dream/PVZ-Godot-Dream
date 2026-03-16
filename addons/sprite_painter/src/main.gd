@tool
class_name SpritePainterRoot
extends Control

signal object_selected(object)

@onready var workspace = $"%Workspace"

var editor_interface : EditorInterface
var editor_plugin : EditorPlugin
var editor_2d_vp : Control
var editor_3d_vp : Control

var viewport_ignored := true
var edited_object : Object
var unsaved_image_paths : Array[String] = []
var undo_redo : EditorUndoRedoManager


func _ready():
	workspace.pre_image_changed.connect(_on_workspace_pre_image_changed)
	workspace.image_changed.connect(_on_workspace_image_changed)
	workspace.image_replaced.connect(_on_workspace_image_replaced)

#	var plugin_undoredo = editor_plugin.get_undo_redo()
#	var own_history_id = plugin_undoredo.get_object_history_id(self)
#	undo_redo = plugin_undoredo.get_history_undo_redo(own_history_id)
#	undo_redo = editor_plugin.get_undo_redo()


func edit_object(obj : Object):
	if obj is Node:
		edit_node(obj)
		edited_object = obj
		object_selected.emit(obj)

	elif obj is CompressedTexture2D:
		edit_file(obj.resource_path)
		edited_object = obj
		object_selected.emit(obj)

	elif obj is AtlasTexture:
		var region = obj.region
		edit_subresource(obj.atlas.resource_path, region.size, region.position, true)
		edited_object = obj
		object_selected.emit(obj)

	else:
		object_selected.emit(obj)


func edit_node(node : Node):
	if node == null:
		return

	mouse_filter = MOUSE_FILTER_STOP if viewport_ignored else MOUSE_FILTER_IGNORE
	if "texture" in node:
		call_deferred("edit_subresource", node.texture.resource_path)


func edit_subresource(
	filepath : String,
	grid_size : Vector2i = Vector2i.ZERO,
	grid_offset : Vector2i = Vector2i.ZERO,
	is_region : bool = false
):
	if unsaved_image_paths.find(StringName(filepath)) == -1:
		unsaved_image_paths.append(StringName(filepath))

	if !is_visible_in_tree(): return

	workspace.edit_texture(filepath)
	if edited_object is Sprite2D || edited_object is Sprite3D:
		update_grid_from_sprite(edited_object)

	else:
		workspace.set_view_grid(grid_size, grid_offset, is_region)


func update_grid_from_sprite(node : CanvasItem):
	var tex_size = Vector2(node.texture.get_size())
	var frame_size = tex_size / Vector2(node.hframes, node.vframes)
	var region_offset = Vector2i.ZERO
	if node.region_enabled:
		frame_size = node.region_rect.size
		region_offset = node.region_rect.position

	workspace.set_view_grid(frame_size, region_offset, node.region_enabled)


func edit_file(filepath : String):
	unsaved_image_paths.append(filepath)
	workspace.edit_texture(filepath)
	workspace.set_view_grid(Vector2i.ZERO, Vector2i.ZERO, false)


func _gui_input(event):
	handle_input(event)


func handle_input(event):
	return workspace.handle_input(event)


static func print_hierarchy(root : Node, indent : String = ""):
	for x in root.get_children(true):
		print(x.name.indent(indent) + " : " + x.get_class())
		print_hierarchy(x, indent + "-   ")


static func save_scene(root : Node, filename = "saved_scn.tscn"):
	for x in root.get_children(true):
		pack_to_owner(root)

	var packed = PackedScene.new()
	packed.pack(root)
	packed.resource_path = "res://" + filename
	ResourceSaver.save(packed)


static func pack_to_owner(root : Node, keep_scene_nodes : bool = true, new_owner : Node = root):
	for x in root.get_children(true):
#		if keep_scene_nodes && root.file_path != "":
#			new_owner = root

		x.owner = new_owner
		pack_to_owner(x, keep_scene_nodes, new_owner)


func _on_close_pressed():
	workspace.rollback_changes()
	editor_plugin._on_enable_pressed()


func _on_save_pressed():
	editor_plugin._on_enable_pressed()


func _on_workspace_pre_image_changed(image : Image, rect):
	if rect.size.x == 0 || rect.size.y == 0:
		return

	undo_redo.create_action("Edit image (start: %s, end: %s)" % [rect.position, rect.end])
	var saved_image = copy_image_rect(image, rect)
	undo_redo.add_undo_method(self, "paste_image_rect", saved_image, image, rect.position)
#	undo_redo.add_undo_method(func edit_undo():
#		paste_image_rect(saved_image, image, rect.position)
#	)


func _on_workspace_image_changed(image : Image, rect):
	if rect.size.x == 0 || rect.size.y == 0:
		return

	var saved_image = copy_image_rect(image, rect)
	undo_redo.add_do_method(self, "paste_image_rect", saved_image, image, rect.position)
#	undo_redo.add_do_method(func edit_do():
#		paste_image_rect(saved_image, image, rect.position)
#	)
	undo_redo.commit_action()


func copy_image_rect(from, rect) -> Image:
	var new_image = Image.create(rect.size.x, rect.size.y, false, from.get_format())
	new_image.blit_rect(from, rect, Vector2.ZERO)
	return new_image


func paste_image_rect(from, to, destination = Vector2.ZERO):
	to.blit_rect(from, Rect2(Vector2.ZERO, from.get_size()), destination)
	save_changes(to)


func save_changes(image = null):
	if image == null:
		image = workspace.edited_image
		if image == null: return

	var err = image.save_png(workspace.edited_image_path.get_basename() + ".png")
	if err != OK: printerr(err)
	workspace.update_texture(image)


func _on_workspace_image_replaced(old_image, new_image):
	undo_redo.create_action("Resize image (%s -> %s)" % [old_image.get_size(), new_image.get_size()])
	undo_redo.add_undo_method(self, "save_changes",
		copy_image_rect(old_image, Rect2i(Vector2i.ZERO, old_image.get_size()))
	)
	undo_redo.add_do_method(self, "save_changes",
		copy_image_rect(new_image, Rect2i(Vector2i.ZERO, new_image.get_size()))
	)
#	undo_redo.add_undo_method(func edit_undo():
#		workspace.edited_image = copy_image_rect(
#			old_image,
#			Rect2i(Vector2i.ZERO, old_image.get_size())
#		)
#	)
#	undo_redo.add_do_method(func edit_do():
#		workspace.edited_image = copy_image_rect(
#			new_image,
#			Rect2i(Vector2i.ZERO, new_image.get_size())
#		)
#	)
	undo_redo.commit_action()
