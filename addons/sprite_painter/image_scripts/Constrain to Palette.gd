extends ImageScript


func _get_param_list():
	return [
		[
			"Palette Texture",
			SCRIPT_PARAM_RESOURCE,
			# Does not work well on gradients: doesn't consider Interp Mode and Width
			# so with no proper spatial partitioning takes an eternity
#			GradientTexture1D.new(),
			null,
			"Texture2D"
		],
	]


func _get_image(new_image, selection):
	if get_param("Palette Texture") == null:
		return new_image

	var palette_img = get_param("Palette Texture").get_image()
	if palette_img == null:
		return new_image

	var palette = {}
	var pix : Color
	for i in palette_img.get_width():
		for j in palette_img.get_height():
			pix = palette_img.get_pixel(i, j)
			if pix.a > 0.01:
				palette[Color(pix, 1.0)] = true

	var image_width = new_image.get_width()
	var image_color_mapping = {}
	var nearest_color : Color
	for i in new_image.get_width():
		for j in new_image.get_height():
			pix = new_image.get_pixel(i, j)
			if image_color_mapping.has(pix):
				if selection.get_bit(i, j):
					new_image.set_pixel(i, j, Color(image_color_mapping[pix], pix.a))

			elif selection.get_bit(i, j):
				# I'll rewrite this into a proper spatial algo access later,
				# bruteforce will do for now
				nearest_color = Color(pick_nearest(pix, palette), 1.0)
				image_color_mapping[Color(pix, 1.0)] = nearest_color
				new_image.set_pixel(i, j, Color(nearest_color, pix.a))

	return new_image


func pick_nearest(to : Color, from : Dictionary):
	var nearest_dist := INF
	var nearest : Color
	var cur_dist : float
	for x in from:
		cur_dist = (
			(x.r - to.r) * (x.r - to.r)
			+ (x.g - to.g) * (x.g - to.g)
			+ (x.b - to.b) * (x.b - to.b)
		)
		if cur_dist < nearest_dist:
			nearest = x
			nearest_dist = cur_dist

	return nearest
