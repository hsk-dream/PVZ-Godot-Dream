@tool
extends EditingTool

var fill_mode := 0
var tolerance := 0.0

var drawing := false
var drawing_color := Color.BLACK
var image : Image
var start_color := Color.TRANSPARENT
var affected_pixels := BitMap.new()
var last_affected_rect := Rect2i()


func _ready():
	add_name()
	start_property_grid()
	add_property("Fill Mode", fill_mode,
		func (x): fill_mode = x,
		TOOL_PROP_ENUM,
		[&"Contiguous", &"Global"]
	)
	add_property("Tolerance", tolerance * 100,
		func (x): tolerance = x * 0.01,
		TOOL_PROP_INT,
		[0, 100],
		true
	)


func mouse_pressed(
	event : InputEventMouseButton,
	image : Image,
	color1 : Color = Color.BLACK,
	color2 : Color = Color.WHITE,
):
	drawing = event.pressed
	drawing_color = Color.BLACK.blend(color1)
	start_color = image.get_pixelv(event.position)
	self.image = image
	if drawing:
		affected_pixels.create(image.get_size())
		fill(event.position)

	else:
		for i in image.get_width():
			for j in image.get_height():
				if affected_pixels.get_bit(i, j):
					set_image_pixel(image, i, j, color1)


func get_affected_rect():
	return last_affected_rect.grow_individual(0, 0, 1, 1)


func mouse_moved(event : InputEventMouseMotion):
	if !drawing: return
	if is_out_of_bounds(event.position, image.get_size()):
		affected_pixels.create(affected_pixels.get_size())
		return

	var cur_color := image.get_pixelv(event.position)
	if cur_color == start_color:
		return
	
	start_color = cur_color
	fill(event.position)


func fill(start_pos : Vector2):
	last_affected_rect = ImageFillTools.fill_on_image(
		image,
		affected_pixels,
		start_pos,
		tolerance,
		(fill_mode == 0) != Input.is_key_pressed(KEY_SHIFT),
		selection
	)


func draw_preview(image_view : CanvasItem, mouse_position : Vector2i):
	if !drawing: return

	image_view.draw_rect(Rect2(mouse_position, Vector2.ONE), Color.WHITE)
	ImageFillTools.draw_bitmap(image_view, affected_pixels, drawing_color)
