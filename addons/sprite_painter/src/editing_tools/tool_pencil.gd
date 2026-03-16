@tool
extends EditingTool

@export var crosshair_color := Color(0.5, 0.5, 0.5, 0.75)
@export var crosshair_size := 3
@export var crosshair_size_ruler := 32

var ruler_mode := false
var jaggies_removal := true

var drawing := false
var drawing_color := Color()
var drawing_positions : Array[Vector2]
var image_size := Vector2()
var last_affected_rect := Rect2i()


func _ready():
	add_name()
	start_property_grid()
	add_property("Guide Lines", ruler_mode,
		func (x): ruler_mode = x,
		TOOL_PROP_BOOL,
		null,
		true
	)
	add_property("Remove Jaggies", jaggies_removal,
		func (x): jaggies_removal = x,
		TOOL_PROP_BOOL
	)
	drawing_positions = []


func mouse_pressed(
	event : InputEventMouseButton,
	image : Image,
	color1 : Color = Color.BLACK,
	color2 : Color = Color.WHITE,
):
	drawing = event.pressed
	drawing_color = Color.BLACK.blend(color1)
	image_size = image.get_size()
	if drawing:
		drawing_positions.clear()
		last_affected_rect = Rect2i(event.position, Vector2i.ZERO)
		_add_point(event.position)

	else:
		for x in drawing_positions:
			set_image_pixelv(image, x, color1)


func get_affected_rect():
	return last_affected_rect.grow_individual(0, 0, 1, 1)


func mouse_moved(event : InputEventMouseMotion):
	if !drawing: return
	var pt_count = max(abs(event.relative.x), abs(event.relative.y))
	var lerp_step = 1 / pt_count
	for i in pt_count:
		_add_point(event.position + Vector2.ONE - event.relative * i * lerp_step - Vector2.ONE)


func _add_point(pt : Vector2):
	pt = pt.floor()
	if drawing_positions.size() >= 1 && drawing_positions[-1] == pt:
		return

	if pt.x < 0 || pt.y < 0 || pt.x >= image_size.x || pt.y >= image_size.y:
		return

	if jaggies_removal && drawing_positions.size() > 2:
		var diff1 = (drawing_positions[-1] - drawing_positions[-2]).abs()
		var diff2 = (pt - drawing_positions[-1]).abs()
		if diff1 != diff2 && diff1.x + diff1.y + diff2.x + diff2.y == 2:
			drawing_positions.pop_back()

	drawing_positions.append(pt)
	last_affected_rect = last_affected_rect.expand(pt)


func draw_preview(image_view : CanvasItem, mouse_position : Vector2i):
	if drawing:
		for x in drawing_positions:
			image_view.draw_rect(Rect2(x, Vector2.ONE), drawing_color)

	if !ruler_mode:
		draw_crosshair(image_view, mouse_position, crosshair_size, crosshair_color)

	else:
		draw_crosshair(image_view, mouse_position, crosshair_size_ruler, crosshair_color)
		var diag_distance := 8
		var posf := Vector2(mouse_position) + Vector2(0.5, 0.5)
		image_view.draw_line(posf + Vector2(-1, +1) * diag_distance, posf + Vector2(-1, +1) * (diag_distance + crosshair_size_ruler), crosshair_color, 1)
		image_view.draw_line(posf + Vector2(+1, -1) * diag_distance, posf + Vector2(+1, -1) * (diag_distance + crosshair_size_ruler), crosshair_color, 1)
		image_view.draw_line(posf + Vector2(+1, +1) * diag_distance, posf + Vector2(+1, +1) * (diag_distance + crosshair_size_ruler), crosshair_color, 1)
		image_view.draw_line(posf + Vector2(-1, -1) * diag_distance, posf + Vector2(-1, -1) * (diag_distance + crosshair_size_ruler), crosshair_color, 1)
