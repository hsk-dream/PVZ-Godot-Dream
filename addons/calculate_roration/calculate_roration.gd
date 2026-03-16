@tool
extends EditorPlugin

const CR_MAIN_UI = preload("res://addons/calculate_roration/ui/CR_main_ui.tscn")
var CR_panel:CrPanelContainer


func _enter_tree():
	CR_panel = CR_MAIN_UI.instantiate()
	#CR_panel.plugin_interface = self
	add_control_to_bottom_panel(CR_panel, "CR_panel")

func _exit_tree():
	remove_control_from_bottom_panel(CR_panel)
