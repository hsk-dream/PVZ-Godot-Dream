@tool
extends "res://addons/sprite_painter/src/editing_tools/tool_brush.gd"

@export var clone_preview_color := Color(0.5, 0.5, 0.5, 0.75)

var replace_alpha := false

var clone_offset := Vector2.ZERO
var clone_offset_editing := false
var source_image : Image
var clone_offset_view : Control


func _ready():
	super._ready()
	clone_offset_view = add_text_display()


func mouse_pressed(
	event : InputEventMouseButton,
	image : Image,
	color1 : Color = Color.BLACK,
	color2 : Color = Color.WHITE,
):
	source_image = image
	if event.button_index == MOUSE_BUTTON_RIGHT:
		clone_offset_editing = event.pressed
		clone_offset = clone_offset.floor()

	else:
		super.mouse_pressed(event, image, color1, color2)


func mouse_moved(event : InputEventMouseMotion):
	if clone_offset_editing:
		clone_offset -= event.relative
		clone_offset_view.text = "Offset: " + str(clone_offset.floor())

	super.mouse_moved(event)


func get_new_pixel(on_image : Image, color : Color, stroke_start : Vector2, stroke_end : Vector2, cur_pos : Vector2, radius : float, solid_radius : float):
	var old_color := on_image.get_pixelv(cur_pos)
	var cloned_color := source_image.get_pixel(
		fposmod(cur_pos.x + clone_offset.x, source_image.get_width()),
		fposmod(cur_pos.y + clone_offset.y, source_image.get_height())
	)
	var distance := Geometry2D.get_closest_point_to_segment(
		cur_pos, stroke_start, stroke_end
	).distance_to(cur_pos)

	if distance <= solid_radius:
		var blended = old_color.blend(cloned_color)
		blended.a = max(old_color.a, cloned_color.a)
		return blended

	elif distance <= radius:
		var blended = old_color.blend(cloned_color)
		distance = (distance - solid_radius) / (radius - solid_radius)
#		blended.a = max(old_color.a, cloned_color.a * (1.0 - distance * distance))
		blended.a = lerp(old_color.a, cloned_color.a, (1.0 - distance * distance))
		return blended

	else:
		return old_color


func draw_preview(image_view : CanvasItem, mouse_position : Vector2i):
	super.draw_preview(image_view, mouse_position)

	if clone_offset == Vector2.ZERO:
		image_view.draw_string(
			get_theme_font("main", "EditorFonts"),
			mouse_position,
			"Hold Right Mouse and drag to change offset.",
			HORIZONTAL_ALIGNMENT_CENTER
		)

	var circle_center := Vector2(mouse_position + Vector2i.ONE + Vector2i(clone_offset)) - brush_offset
	image_view.draw_arc(circle_center, brushsize * 0.5 + 0.5, PI * 0.6, PI * 1.4, 32, clone_preview_color, 1.0)
	image_view.draw_arc(circle_center, brushsize * 0.5 + 0.5, PI * 1.6, PI * 2.4, 32, clone_preview_color, 1.0)
