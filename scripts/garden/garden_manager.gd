extends Node2D
class_name GardenManager

@export var bgm:AudioStream

## 花园背景种类
enum E_GardenBgType{
	GreenHouse,		## 阳光房
	MushroomGraden,	## 蘑菇花园
	Aquarium,		## 水族馆
	#TreeBg,			## 智慧树
}
## 植物成长状态
enum E_GrowthStage {
	Sprout,
	Small,
	Medium,
	Large,
	Perfect,		## 当前植物处于完美状态
}
## 需要的物品
enum E_NeedItem{
	Null,			## 不需要
	WateringCan,	## 水壶
	Fertilizer,		## 肥料
	BugSpray,		## 杀虫剂
	Phonograph,		## 留声机
}

## 当前花园背景页
@export var curr_bg_type:E_GardenBgType=E_GardenBgType.GreenHouse
@export var curr_page:=0
@onready var page_info_label: Label = $CanvasLayer/Next/Label
@onready var page_info_label2: Label = $CanvasLayer/Next/Label2
@onready var num_new_plant_no_plant_cell: Label = $CanvasLayer/NumNewPlantNoPlantCell

@onready var store_enter_key: PVZButtonBase = $CanvasLayer/StoreEnterKey

## 当前背景页的节点
var curr_bg_page_node :GardenBgPage

## ui按钮和对应的物品
@onready var item_buttons: Array[UiItemButton] = [
	$CanvasLayer/PanelUI/HBoxContainer/GardenItemButton,
	$CanvasLayer/PanelUI/HBoxContainer/GardenItemButton2,
	$CanvasLayer/PanelUI/HBoxContainer/GardenItemButton3,
	$CanvasLayer/PanelUI/HBoxContainer/GardenItemButton4,
	$CanvasLayer/PanelUI/HBoxContainer/GardenItemButton5,
	$CanvasLayer/PanelUI/HBoxContainer/GardenItemButton6,
	$CanvasLayer/PanelUI/HBoxContainer/GardenItemButton7,
	$CanvasLayer/PanelUI/HBoxContainer/GardenItemButton8
]

@onready var items: Array[ItemBase] = [
	$CanvasLayer/Items/WateringCan,
	$CanvasLayer/Items/Fertilizer,
	$CanvasLayer/Items/BugSpray,
	$CanvasLayer/Items/Phonograph,
	$CanvasLayer/Items/Chocolate,
	$CanvasLayer/Items/Glove,
	$CanvasLayer/Items/MoneySign,
	$CanvasLayer/Items/WheelBarrow
]

## 手套，与水族馆背景植物格子信号连接
@onready var glove: GardenGlove = $CanvasLayer/Items/Glove
## 独轮车，与水族馆背景植物格子信号连接
@onready var wheel_barrow: WheelBarrow = $CanvasLayer/Items/WheelBarrow
## 商店场景画布
@onready var canvas_layer_store: CanvasLayer = $CanvasLayerStore


## 当前物品
var curr_item


## 阳光房场景
const BgPageScenes = {
	E_GardenBgType.GreenHouse:    preload("res://scenes/garden/bg_00_greenhouse.tscn"),
	E_GardenBgType.MushroomGraden:preload("res://scenes/garden/bg_01_mushroom_garden.tscn"),
	E_GardenBgType.Aquarium:      preload("res://scenes/garden/bg_02_aquarium.tscn")
}

var curr_bg := []

func _ready() -> void:
	## bgm
	SoundManager.play_bgm(bgm)

	## 连接ui物品信号
	for i in range(item_buttons.size()):
		var item_button:UiItemButton = item_buttons[i]
		var item:ItemBase = items[i]
		item_button.ui_item_button_signal.connect(on_button_ui_item.bind(item))

		item.item_button = item_button
		item.is_clone = false

	## 独轮车植物数据
	var wheel_barrow_plant_data = Global.global_game_state.garden_data.get("WheelBarrow", {})
	if wheel_barrow_plant_data:
		wheel_barrow.init_from_data(wheel_barrow_plant_data)

	## 初始化第一类的第一页
	init_new_page()

	store_enter_key.pressed.connect(_on_store_enter_key_pressed)

func init_new_page():
	## 背景种类
	var curr_bg_data = Global.global_game_state.garden_data.get("第"+str(curr_bg_type)+"类背景", {})
	## 当前背景种类的页码数据
	var curr_bg_page_data = curr_bg_data.get("第"+str(curr_page)+"页", {})

	curr_bg_page_node = BgPageScenes[curr_bg_type].instantiate()
	add_child(curr_bg_page_node)
	## 初始化当前背景，获取其空闲植物格子
	var empty_plant_cells:Array[Node] = curr_bg_page_node.init_curr_gb_page(curr_bg_page_data, curr_page)

	## 温室背景
	if curr_bg_type == 0:
		## 新增植物数量和空闲格子的数量的最小值
		for i in range(min(Global.global_game_state.curr_num_new_garden_plant, empty_plant_cells.size())):
			var empty_plant_cell:PlantCellGarden =  empty_plant_cells[i]
			empty_plant_cell.init_new_plant_cell()
			Global.global_game_state.curr_num_new_garden_plant -= 1
		num_new_plant_no_plant_cell.text = "待放置植物数量:" + str(Global.global_game_state.curr_num_new_garden_plant)

	page_info_label.text = str(curr_page + 1) + "/" + str(int(Global.global_game_state.garden_data["num_bg_page_" + str(curr_bg_type)]))
	page_info_label2.text = str(curr_bg_type + 1) + "/" + str(E_GardenBgType.size())


## 从商店返回后更新
func _update_back_from_store():
	## 如果有新植物
	init_new_page()
	num_new_plant_no_plant_cell.text = "待放置植物数量:" + str(Global.global_game_state.curr_num_new_garden_plant)
	page_info_label.text = str(curr_page + 1) + "/" + str(int(Global.global_game_state.garden_data["num_bg_page_" + str(curr_bg_type)]))
	page_info_label2.text = str(curr_bg_type + 1) + "/" + str(E_GardenBgType.size())


##更新当前页花园数据
func save_curr_page_data():
	var curr_bg_page_data:Dictionary = {}
	for i in range(curr_bg_page_node.all_plant_cells.size()):
		var plant_cell :PlantCellGarden = curr_bg_page_node.all_plant_cells[i]
		curr_bg_page_data["第" + str(i) + "个植物格子"] = plant_cell.get_curr_plant_cell_data()

	## 若当前类背景数据还未初始化
	if "第"+str(curr_bg_type)+"类背景" not in Global.global_game_state.garden_data:
		Global.global_game_state.garden_data["第"+str(curr_bg_type)+"类背景"] = {}
	Global.global_game_state.garden_data["第"+str(curr_bg_type)+"类背景"]["第"+str(curr_page)+"页"] = curr_bg_page_data
	## 独轮车信息
	Global.global_game_state.garden_data["WheelBarrow"] = wheel_barrow.choosed_plant_data
	Global.save_service.save_now()

#region 按钮信号连接函数

## 点击商店页
func _on_store_enter_key_pressed():
	## 先保存当前页数据
	save_curr_page_data()
	## 删除上一页的节点
	curr_bg_page_node.queue_free()

	SoundManager.play_other_SFX("tap")
	## 商店场景添加为子节点
	var store_node:StoreManager = load(Global.main_scene_registry.MainScenesMap[EnumsMainScene.MainScenes.Store]).instantiate()
	canvas_layer_store.add_child(store_node)
	store_node.siganl_exit_store.connect(_update_back_from_store)


## 跳转到下一页背景
func _on_next_pressed() -> void:
	## 先保存当前页数据
	save_curr_page_data()

	## 播放音效
	SoundManager.play_other_SFX("tap")
	## 更新页面和种类
	curr_page += 1
	if curr_page >= Global.global_game_state.garden_data["num_bg_page_" + str(curr_bg_type)]:
		curr_page = 0
		curr_bg_type = (int(curr_bg_type) + 1) as E_GardenBgType
		if curr_bg_type >= E_GardenBgType.size():
			curr_bg_type = 0 as E_GardenBgType

	## 删除上一页的节点，初始化新页
	curr_bg_page_node.queue_free()
	init_new_page()

## 点击ui物品按钮时，ui物品按钮在_ready()中信号连接该函数
func on_button_ui_item(item:ItemBase):

	## 播放音效
	SoundManager.play_other_SFX("tap2")
	curr_item = item
	item.activete_it()

## 返回菜单按钮
func _on_return_start_menu_pressed() -> void:
	save_curr_page_data()
	get_tree().change_scene_to_file(Global.main_scene_registry.MainScenesMap[EnumsMainScene.MainScenes.StartMenu])

#endregion
