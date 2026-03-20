extends Control
class_name MainAlmanac

#region 主要页面
@onready var start_page: TextureRect = $StartPage
@onready var plant_page: AlmanacPlantPage = $PlantPage
@onready var zombie_page: AlmanacZombiePage = $ZombiePage

#endregion


func _ready() -> void:
	_on_return_button_pressed()

	if Global.data_almanac.is_empty():
		Global.data_almanac = Global.load_json(Global.PathDataAlmanac)

	plant_page.init_almanac_page()
	zombie_page.init_almanac_page()

## 返回开始菜单
func _on_exit_button_pressed() -> void:
	## 如果当前场景为图鉴场景
	if get_tree().current_scene == self:
		get_tree().change_scene_to_file(Global.main_scene_registry.MainScenesMap[EnumsMainScene.MainScenes.StartMenu])
	## 从其余场景进入图鉴场景
	else:
		queue_free()

## 查看植物图鉴
func _on_plant_button_pressed() -> void:
	start_page.visible = false
	plant_page.visible = true
	zombie_page.visible = false

## 查看僵尸图鉴
func _on_zombie_button_pressed() -> void:
	start_page.visible = false
	plant_page.visible = false
	zombie_page.visible = true

## 返回图鉴索引
func _on_return_button_pressed() -> void:
	start_page.visible = true
	plant_page.visible = false
	zombie_page.visible = false

