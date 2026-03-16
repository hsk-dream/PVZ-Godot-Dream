@tool
extends "./tool_select.gd"

var selection_operations = [
	func(s, d): return d,
	func(s, d): return s || d,
	func(s, d): return s && !d,
	func(s, d): return s && d,
	func(s, d): return s != d,
]

var fill_mode := 0
var tolerance := 0.0


func _ready():
	add_name()
	start_property_grid()
	add_selection_common_properties()
	add_property("Fill Mode", fill_mode,
		func (x): fill_mode = x,
		TOOL_PROP_ENUM,
		[&"Contiguous", &"Global"]
	)
	add_property("Tolerance", tolerance * 100,
		func (x): tolerance = x * 0.01,
		TOOL_PROP_INT,
		[0, 100]
	)
	add_selection_button_panel()


func apply_selection(add_modifier, subtract_modifier):
	var affected_pixels = BitMap.new()
	affected_pixels.create(image_size)
	var affected_rect = ImageFillTools.fill_on_image(
		image,
		affected_pixels,
		draw_end,
		tolerance,
		(fill_mode == 0) != Input.is_key_pressed(KEY_SHIFT)
	)
	affected_rect.size += Vector2i.ONE
	var used_op_index = operation
	if operation == OPERATION_REPLACE || is_selection_empty():
		if !add_modifier && !subtract_modifier:
			selection.set_bit_rect(Rect2i(Vector2i.ZERO, image_size), false)

	if add_modifier:
		used_op_index = OPERATION_ADD

	var used_op = selection_operations[used_op_index]
	var cur_pos : Vector2i
	for i in affected_rect.size.x:
		for j in affected_rect.size.y:
			cur_pos = Vector2i(i, j) + affected_rect.position
			if !affected_pixels.get_bitv(cur_pos): continue
			selection.set_bitv(cur_pos, used_op.call(
				selection.get_bitv(cur_pos), true
			) != subtract_modifier)


func draw_selection_preview(image_view : CanvasItem, mouse_position : Vector2i):
	var affected_pixels = BitMap.new()
	affected_pixels.create(image_size)
	var affected_rect = ImageFillTools.fill_on_image(
		image,
		affected_pixels,
		draw_end,
		tolerance,
		(fill_mode == 0) != Input.is_key_pressed(KEY_SHIFT)
	)
	ImageFillTools.draw_bitmap(image_view, affected_pixels, preview_color)
