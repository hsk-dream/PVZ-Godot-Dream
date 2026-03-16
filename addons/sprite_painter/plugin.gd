@tool
extends EditorPlugin

const can_edit_properties := [
	"texture",
	"tile_set",
	"frames", # AnimatedSprite
	"texture_normal", # TextureButton
	"texture_progress", # Self explanatory
]

const can_edit_types := [
	"CompressedTexture2D",
	"AtlasTexture",
	"SpriteFrames",
	"TileSet",
]

var editor_view : Control
var editor_2d_vp : Control
var editor_3d_vp : Control
var enable_buttons : Dictionary
var sploinky := Control.new()
var sploinky3 := Control.new()
var undo_redo : EditorUndoRedoManager

var overlay_enabled := false


func _enter_tree() -> void:
	# Sometimes crashes on startup. Until I find why, let this be here
	await get_tree().create_timer(2.0)

	var ui := get_editor_interface()

	undo_redo = get_undo_redo()
	editor_view = load(get_script().resource_path.get_base_dir() + "/src/main.tscn").instantiate()
	editor_view.editor_interface = ui
	editor_view.editor_plugin = self
	editor_view.undo_redo = undo_redo

	_connect_editor_viewports()
	_add_enable_button(EditorPlugin.CONTAINER_CANVAS_EDITOR_MENU)
	_add_enable_button(EditorPlugin.CONTAINER_SPATIAL_EDITOR_MENU)

	main_screen_changed.connect(_on_main_screen_changed)
	ui.get_selection().selection_changed.connect(_on_selection_changed)

	ui.get_base_control().add_child(editor_view)

	make_visible(false)


func _forward_canvas_gui_input(event):
	if !overlay_enabled:
		return false

	return editor_view.handle_input(event)


func _connect_editor_viewports():
	var mainscreen = get_editor_interface().get_editor_main_screen()
	mainscreen.resized.connect(_on_editor_resized.bind(mainscreen))
	for x in mainscreen.get_children():
		if x.get_class() == "CanvasItemEditor":
			editor_2d_vp = x
			editor_view.editor_2d_vp = x
			x.add_child(sploinky)
			x.move_child(sploinky, 1)

		if x.get_class() == "Node3DEditor":
			editor_3d_vp = x
			editor_view.editor_3d_vp = x
			x.add_child(sploinky3)
			x.move_child(sploinky3, 1)

	call_deferred("_on_editor_resized", mainscreen)


func _add_enable_button(container_id):
	var enable_button = Button.new()
	add_control_to_container(container_id, enable_button)
	
	enable_button.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	enable_button.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
	enable_button.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
	enable_button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	enable_button.icon = enable_button.get_theme_icon("StyleBoxTexture", "EditorIcons")
	enable_button.text = "Edit Texture..."
	enable_button.pressed.connect(_on_enable_pressed)
	enable_button.hide()

	enable_buttons[container_id] = enable_button


func _exit_tree() -> void:
	make_visible(false)
	editor_view.queue_free()
	sploinky.queue_free()
	sploinky3.queue_free()
	for x in enable_buttons.values():
		x.queue_free()


func make_visible(visible):
	if !is_instance_valid(editor_view): return
	if editor_view.visible == visible: return

	editor_view.visible = visible
	editor_2d_vp.get_child(0).visible = !visible
	editor_3d_vp.get_child(0).visible = !visible
	sploinky.custom_minimum_size.y = editor_2d_vp.get_child(0).size.y
	sploinky3.custom_minimum_size.y = editor_3d_vp.get_child(0).size.y
	sploinky.visible = visible
	sploinky3.visible = visible
	if visible:
		editor_view.edit_object(editor_view.edited_object)
	
	else:
		editor_view.save_changes()
		if editor_view.unsaved_image_paths.size() == 0:
			return

#		print("Saved images: " + str(editor_view.unsaved_image_paths))
		get_editor_interface()\
			.get_resource_filesystem()\
			# I am totally done with this thing freezing the editor forever,
			# Yes it is more efficient, but stability matters more
#			.reimport_files(editor_view.unsaved_image_paths)
			.scan()
		editor_view.unsaved_image_paths.clear()


func _edit(object):
	editor_view.edit_object(object)
	for x in enable_buttons.values():
		x.show()

	if overlay_enabled:
		make_visible(true)


func _handles(object):
	for x in can_edit_properties:
		if x in object:
			return true

	for x in can_edit_types:
		if ClassDB.is_parent_class(object.get_class(), x):
			return true

	return false


func _on_enable_pressed():
	overlay_enabled = !overlay_enabled
	make_visible(overlay_enabled)


func _on_main_screen_changed(screen):
	overlay_enabled = false
	make_visible(false)


func _on_selection_changed():
	var sel = get_editor_interface().get_selection().get_selected_nodes()
	if sel.size() == 0 || !_handles(sel[-1]):
		for x in enable_buttons.values():
			x.hide()

		overlay_enabled = false
		make_visible(false)

	else:
		for x in enable_buttons.values():
			x.show()


func _on_editor_resized(mainscreen : Control):
	editor_view.size = mainscreen.size
	editor_view.global_position = mainscreen.global_position
