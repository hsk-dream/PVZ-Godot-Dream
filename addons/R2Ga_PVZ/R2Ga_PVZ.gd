@tool
extends EditorPlugin

## 底部工具面板的场景资源，由插件创建和释放实例。
const MY_PANEL_MAIN_PANEL = preload("res://addons/R2Ga_PVZ/ui/main_panel.tscn")
## 插件持有的面板实例；退出时释放并清空引用。
var R2Ga_panel : MyPanelMainContainer


func _enter_tree():
	R2Ga_panel = MY_PANEL_MAIN_PANEL.instantiate()
	R2Ga_panel.plugin_interface = self
	add_control_to_bottom_panel(R2Ga_panel, "R2Ga_PVZ")

## 插件退出时移除并释放面板，清空双方引用。
func _exit_tree() -> void:
	remove_control_from_bottom_panel(R2Ga_panel)
	R2Ga_panel.plugin_interface = null
	R2Ga_panel.queue_free()
	R2Ga_panel = null

func refresh_resources():
	get_editor_interface().get_resource_filesystem().scan()
