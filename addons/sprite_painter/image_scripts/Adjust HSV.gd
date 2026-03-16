extends ImageScript


func _get_param_list():
	return [
		[
			"Hue",
			SCRIPT_PARAM_INT,
			0,
			[0, 360]
		],
		[
			"Saturation",
			SCRIPT_PARAM_INT,
			0,
			[-100, +100]
		],
		[
			"Value",
			SCRIPT_PARAM_INT,
			0,
			[-100, +100]
		],
	]


func _get_image(new_image, selection):
	var pix : Color
	for i in new_image.get_width():
		for j in new_image.get_width():
			if !selection.get_bit(i, j): continue
			pix = new_image.get_pixel(i, j)
			pix.h += get_param("Hue") / 360.0
			pix.s *= 1.0 + get_param("Saturation") * 0.01
			pix.v *= 1.0 + get_param("Value") * 0.01
			new_image.set_pixel(i, j, pix)

	return new_image
