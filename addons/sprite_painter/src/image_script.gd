class_name ImageScript
extends RefCounted

## Base class for scripts that process images through Sprite painter.
##
## Extend this script and add the new file to `res://addons/sprite_painter/image_scripts/`
## to make it usable in Sprite Painter.

enum {
	SCRIPT_PARAM_BOOL, ## Checkbox property. No hints.
	SCRIPT_PARAM_INT, ## Integer number property. Hints: [MINVALUE, MAXVALUE]
	SCRIPT_PARAM_FLOAT, ## Floating-point number property. Hints: [MINVALUE, MAXVALUE]
	SCRIPT_PARAM_ENUM, ## Enumeration property. Hint is an array of names for the created OptionButton.
	SCRIPT_PARAM_ICON_ENUM, ## Enumeration property. Hint is an dictionary of {ICON : TOOLTIP} pairs. ICON can be a theme icon name or a loaded Texture.
	SCRIPT_PARAM_ICON_FLAGS, ## Array of Bools property. Hint is an dictionary of {ICON : TOOLTIP} pairs. ICON can be a theme icon or a loaded Texture.
	SCRIPT_PARAM_RESOURCE, ## Resource property. Hint is the base type of accepted Resources.
	SCRIPT_PARAM_FILE, ## Resource property. Allows choosing a file from a folder set in a hint.
	SCRIPT_PARAM_COLOR, ## Color property. No hints.
}

var _params = {}

## Returns a parameter set through the GUI.
##
## Key must be same as passed in `_get_param_list()`.
func get_param(key : String) -> Variant:
	return _params[key]

## Called when the script is loaded: when switching scripts, opening an image, or resetting parameters.
func _ready(image : Image):
	pass

## Called to preview or apply the script. Must return the result, which can be the same image object.
func _get_image(new_image : Image, selection : BitMap) -> Image:
	return new_image

## Must return a list of parameters. Each parameter contains:
##
## - Name
##
## - Type
##
## - Default
##
## - Type Hint, for which refer to ImageScript's class.
func _get_param_list():
	return [
		[
			"_get_param_list() Not overriden!",
			SCRIPT_PARAM_ENUM,
			0,
			["Refer to the ImageScript class for more info."]
		],
	]
