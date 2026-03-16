@tool
extends EditorPlugin
const MY_PANEL_MAIN_PANEL = preload("res://addons/anim_free_common_tracks/ui/main_panel.tscn")
var anim_delete_track_panel : AFPanelMainContainer

func _enter_tree():
	anim_delete_track_panel = MY_PANEL_MAIN_PANEL.instantiate()
	anim_delete_track_panel.plugin_interface = self
	add_control_to_bottom_panel(anim_delete_track_panel, "anim_free_common_tracks")

func _exit_tree():
	remove_control_from_bottom_panel(anim_delete_track_panel)

func refresh_resources():
	get_editor_interface().get_resource_filesystem().scan()
