@tool
class_name ImageFillTools


static func fill_on_image(
	image : Image,
	result_into_mask : BitMap,
	start_pos : Vector2i,
	tolerance : float = 0.0,
	fill_contiguous : bool = true,
	selection : BitMap = null,
) -> Rect2i:
	var affected_rect : Rect2i
	result_into_mask.create(image.get_size())
	if fill_contiguous:
		affected_rect = flood_fill(image, result_into_mask, start_pos, tolerance, selection)

	else:
		affected_rect = global_fill(image, result_into_mask, start_pos, tolerance)

	return affected_rect


static func flood_fill(
	image : Image,
	result_into_mask : BitMap,
	start_pos : Vector2i,
	tolerance : float = 0.0,
	selection : BitMap = null
) -> Rect2i:
	var start_color = image.get_pixelv(start_pos)
	var affected_rect = Rect2i(start_pos, Vector2.ZERO)
	var q = [start_pos]
	while q.size() > 0:
		var x = q.pop_front()
		result_into_mask.set_bitv(x, true)
		for pos in [x + Vector2i.RIGHT, x + Vector2i.DOWN, x + Vector2i.LEFT, x + Vector2i.UP]:
			if (
				is_out_of_bounds(pos, image.get_size())
				|| result_into_mask.get_bitv(pos)
				|| (selection != null && !selection.get_bitv(pos))
			):
				continue

			if tolerance == 1.0 || get_color_distance_squared(start_color, image.get_pixelv(pos)) <= tolerance:
				affected_rect = affected_rect.expand(pos)
				result_into_mask.set_bitv(pos, true)
				q.append(pos)

	return affected_rect


static func global_fill(
	image : Image,
	result_into_mask : BitMap,
	start_pos : Vector2i,
	tolerance : float = 0.0
) -> Rect2i:
	var start_color = image.get_pixelv(start_pos)
	var affected_rect = Rect2i(start_pos, Vector2.ZERO)
	for i in image.get_width():
		for j in image.get_height():
			if tolerance == 1.0 || get_color_distance_squared(start_color, image.get_pixel(i, j)) <= tolerance:
				affected_rect = affected_rect.expand(Vector2i(i, j))
				result_into_mask.set_bit(i, j, true)

	return affected_rect


static func get_color_distance_squared(a : Color, b : Color) -> float:
	if a.a + b.a == 0.0: return 0.0
	return (
		(a.r - b.r) * (a.r - b.r)
		+ (a.g - b.g) * (a.g - b.g)
		+ (a.b - b.b) * (a.b - b.b)
		+ (a.a - b.a) * (a.a - b.a)
	) * 0.33333


static func draw_bitmap(on_node : CanvasItem, bitmap : BitMap, color : Color, offset : Vector2 = Vector2(0, 0)):
	var map_size = bitmap.get_size()
	var draw_next = false
	var rect_height = 0
	var draw_pos : Vector2
	for i in map_size.x:
		for j in map_size.y:
			if bitmap.get_bit(i, j) != draw_next || j == 0:
				if rect_height >= 1 && draw_next:
					draw_pos = Vector2(i, j - rect_height)
					if j == 0:
						draw_pos = Vector2(i - 1, map_size.y - rect_height)

					on_node.draw_rect(Rect2(
						draw_pos + offset,
						Vector2(1, rect_height)
					), color)

				rect_height = 0

			rect_height += 1
			draw_next = bitmap.get_bit(i, j)

	on_node.draw_rect(Rect2(
		offset + Vector2(map_size.x - 1, map_size.y - rect_height),
		Vector2(1, rect_height)
	), color)


static func is_out_of_bounds(pos : Vector2i, rect_size : Vector2i) -> bool:
	return (
		pos.x < 0 || pos.y < 0
		|| pos.x >= rect_size.x || pos.y >= rect_size.y
	)
