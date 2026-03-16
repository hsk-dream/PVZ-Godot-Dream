@tool
extends PanelContainer
class_name CrPanelContainer

@onready var text_edit: TextEdit = $VBoxContainer/TextEdit
@onready var button: Button = $VBoxContainer/HBoxContainer/Button
@onready var check_button: CheckButton = $VBoxContainer/HBoxContainer/CheckButton
@onready var text_edit_2: TextEdit = $VBoxContainer/TextEdit2
@onready var text_edit_3: TextEdit = $VBoxContainer/TextEdit3

func _on_button_pressed() -> void:
	var content := text_edit.text
	var regex := RegEx.new()
	regex.compile(r"[-+]?(?:\d+\.?\d*|\d*\.?\d+)(?:[eE][-+]?\d+)?") # 支持科学计数法

	var result := ""
	var last_end := 0
	var angle_in_degrees = float(text_edit_3.text)
	var offset := deg_to_rad(angle_in_degrees)

	if check_button.button_pressed:
		offset = -offset

	for match in regex.search_all(content):
		result += content.substr(last_end, match.get_start() - last_end)
		var num := float(match.get_string())
		var rotated := num + offset
		var rotated_rounded := "%0.6f" % rotated
		result += str(rotated_rounded)
		last_end = match.get_end()

	result += content.substr(last_end)
	text_edit_2.text = result
