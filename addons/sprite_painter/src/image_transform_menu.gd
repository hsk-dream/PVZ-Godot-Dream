@tool
extends MenuButton

enum {
	OPTION_ROTATE_CW,
	OPTION_ROTATE_CCW,
	OPTION_FLIP_H,
	OPTION_FLIP_V,
	OPTION_CROP,
	OPTION_BORDER,
	OPTION_RESIZE,
}

@export var workspace : NodePath

@onready var width_edit = $"Dialog/Grid/Width"
@onready var height_edit = $"Dialog/Grid/Height"

var original_size := Vector2i()
var expand_dir := Vector2i()
var percent_view := false
var stretch := false
var interp := 0


func _ready():
	var dir_buttons = $"Dialog/Grid/Box/Grid".get_children()
	$"Dialog/Grid/Box/Stretch".pressed.connect(_on_stretch_pressed)
	for i in 9:
		dir_buttons[i].pressed.connect(func():
			_on_anchor_dir_pressed(Vector2i(1 - i % 3, 1 - i / 3))
		)

	var p = get_popup()
	p.id_pressed.connect(_on_id_pressed)
	p.hide_on_item_selection = false

	if !get_viewport() is Window: return
	p.set_item_icon(OPTION_ROTATE_CW, get_theme_icon("RotateRight", "EditorIcons"))
	p.set_item_icon(OPTION_ROTATE_CCW, get_theme_icon("RotateLeft", "EditorIcons"))
	p.set_item_icon(OPTION_FLIP_H, get_theme_icon("MoveRight", "EditorIcons"))
	p.set_item_icon(OPTION_FLIP_V, get_theme_icon("MoveDown", "EditorIcons"))
	# One of them is not real.
	# p.set_item_icon(OPTION_FLIP_H, get_theme_icon("Hsize", "EditorIcons"))
	# p.set_item_icon(OPTION_FLIP_V, get_theme_icon("VSize", "EditorIcons"))
	p.set_item_icon(OPTION_CROP + 1, get_theme_icon("MeshTexture", "EditorIcons"))
	p.set_item_icon(OPTION_BORDER + 1, get_theme_icon("ToolMove", "EditorIcons"))
	p.set_item_icon(OPTION_RESIZE + 1, get_theme_icon("DistractionFree", "EditorIcons"))


func _on_id_pressed(id):
	var old_image = get_node(workspace).edited_image
	original_size = old_image.get_size()
	if id == OPTION_CROP:
		crop(old_image, get_node(workspace).edited_image_selection)
		return

	elif id == OPTION_RESIZE:
		$"Dialog".popup_centered()
		update_entered_size(original_size)
		return
	
	elif id == OPTION_BORDER:
		var new_image = get_node(workspace).get_resized(
			old_image,
			original_size + Vector2i(2, 2),
			Vector2i(0, 0),
			-1
		)

		submit_changed_image(new_image)
		return

	var new_image = Image.create(original_size.x, original_size.y, false, old_image.get_format())
	new_image.blit_rect(old_image, Rect2(Vector2i.ZERO, original_size), Vector2i.ZERO)
	match id:
		OPTION_ROTATE_CW:
			new_image.rotate_90(CLOCKWISE)

		OPTION_ROTATE_CCW:
			new_image.rotate_90(COUNTERCLOCKWISE)

		OPTION_FLIP_H:
			new_image.flip_x()

		OPTION_FLIP_V:
			new_image.flip_y()

	submit_changed_image(new_image)


func crop(old_image, selection):
	var result_rect = Rect2i(0, 0, 0, 0)
	var found_start = false
	original_size = old_image.get_size()
	var sel_bits = selection.get_true_bit_count()
	var crop_selection = sel_bits > 2 && sel_bits < original_size.x * original_size.y
	for i in original_size.x:
		for j in original_size.y:
			if crop_selection:
				if !selection.get_bit(i, j):
					continue
			
			elif old_image.get_pixel(i, j).a < 0.02:
				continue

			if !found_start:
				found_start = true
				result_rect.position = Vector2i(i, j)

			else:
				result_rect = result_rect.expand(Vector2i(i, j))

	result_rect.size += Vector2i.ONE
	if result_rect.size == Vector2i.ONE:
		return

	var new_image = Image.create(
		result_rect.size.x,
		result_rect.size.y,
		false,
		old_image.get_format()
	)
	new_image.blit_rect(old_image, result_rect, Vector2i.ZERO)
	submit_changed_image(new_image)


func get_entered_size():
	if percent_view:
		return Vector2i(
			original_size.x * width_edit.value * 0.01,
			original_size.y * height_edit.value * 0.01
		)
	
	else:
		return Vector2i(
			width_edit.value,
			height_edit.value
		)


func update_entered_size(new_size):
	if percent_view:
		width_edit.prefix = ""
		width_edit.value = new_size.x * 100.0 / original_size.x
		width_edit.suffix = "%"
		width_edit.step = 0.01

		height_edit.prefix = ""
		height_edit.value = new_size.y * 100.0 / original_size.y
		height_edit.suffix = "%"
		height_edit.step = 0.01

	else:
		width_edit.prefix = str(original_size.x) + " -> "
		width_edit.value = new_size.x
		width_edit.suffix = "px"
		width_edit.step = 1

		height_edit.prefix = str(original_size.y) + " -> "
		height_edit.value = new_size.y
		height_edit.suffix = "px"
		height_edit.step = 1


func submit_changed_image(new_image):
	var ws = get_node(workspace)
	ws.image_replaced.emit(ws.edited_image, new_image)
	ws.update_texture(new_image)


func _on_dialog_confirmed():
	var ws = get_node(workspace)
	var new_image = ws.get_resized(
		ws.edited_image,
		get_entered_size(),
		expand_dir,
		interp if stretch else -1
	)

	submit_changed_image(new_image)


func _on_anchor_dir_pressed(direction):
	$"Dialog/Grid/Interpolation".disabled = true
	stretch = false
	expand_dir = direction


func _on_stretch_pressed():
	$"Dialog/Grid/Interpolation".disabled = false
	stretch = true


func _on_interpolation_item_selected(index):
	interp = index


func _on_percent_toggled(v):
	var old_entered_size = get_entered_size()
	percent_view = v
	update_entered_size(old_entered_size)
