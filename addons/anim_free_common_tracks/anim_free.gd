@tool
extends EditorPlugin
## 底部工具面板的场景资源，由插件创建和释放实例。
const MY_PANEL_MAIN_PANEL = preload("res://addons/anim_free_common_tracks/ui/main_panel.tscn")
## 插件持有的面板实例；退出时释放并清空引用。
var anim_delete_track_panel : AFPanelMainContainer

func _enter_tree():
	anim_delete_track_panel = MY_PANEL_MAIN_PANEL.instantiate()
	anim_delete_track_panel.plugin_interface = self
	add_control_to_bottom_panel(anim_delete_track_panel, "anim_free_common_tracks")

## 插件退出时移除并释放面板，清空双方引用。
func _exit_tree() -> void:
	remove_control_from_bottom_panel(anim_delete_track_panel)
	anim_delete_track_panel.plugin_interface = null
	anim_delete_track_panel.queue_free()
	anim_delete_track_panel = null

func refresh_resources():
	get_editor_interface().get_resource_filesystem().scan()
