extends TextureRect
## 待选卡槽
class_name CardSlotCandidate

## 所有卡片页面的父节点
@onready var all_card_page: Control = $AllCardPage
## 卡片Grid
@onready var grid_container_plant: GridContainer = $AllCardPage/GridContainerPlant
@onready var grid_container_zombie: GridContainer = $AllCardPage/GridContainerZombie

## 所有的备选卡片
var all_card_candidate_containers_plant:Dictionary[int, CardCandidateContainer] = {}
var all_card_candidate_containers_zombie:Dictionary[int, CardCandidateContainer] = {}

## 所有的卡片页面列表
var all_card_page_array:Array[GridContainer] =[]
## 当前页
var curr_page := 0

## 模仿者卡槽对应的父节点
@onready var all_imitater_card: Control = %AllImitaterCard
## 模仿者卡片页面的父节点
@onready var all_card_page_imitater: Control = $AllImitaterCard/Panel/AllCardPageImitater
## 模仿者卡片Grid
@onready var grid_container_plant_imitater: GridContainer = $AllImitaterCard/Panel/AllCardPageImitater/GridContainerPlantImitater

## 所有的模仿者备选卡片
var all_card_candidate_containers_plant_imitater:Dictionary[int, CardCandidateContainer] = {}
## 模仿者卡片背景
@onready var imitater_bg: TextureRect = $ImitaterBG
## 模仿者卡片
@onready var card_imitater: CardImitater = $ImitaterBG/CardImitater
## 所有的模仿者卡片页面列表
var all_card_page_array_imitater:Array[GridContainer] =[]
## 当前模仿者卡片页
var curr_page_imitater := 0


func _ready() -> void:
	_init_card_slot_candidate_plant()
	_init_card_slot_candidate_zombie()
	curr_page = 0
	all_card_page_array[0].visible = true
	_init_card_slot_candidate_imitater()
	curr_page_imitater = 0
	all_card_page_array_imitater[0].visible = true

	card_imitater.signal_card_click.connect(imitater_card_slot_appear)


## 初始化生成植物待选卡槽
func _init_card_slot_candidate_plant():
	## 每一页的卡片数量
	var num_card_every_page = grid_container_plant.get_child_count()
	all_card_page.remove_child(grid_container_plant)
	## 当前页面的所有卡片占位
	var card_selected_placeholder:Array
	var curr_num_page:int = -1
	for i:int in Global.global_game_state.curr_plant.size():
		var page_i:int = int(float(i) / num_card_every_page)
		if curr_num_page < page_i:
			curr_num_page += 1
			var new_grid_container = grid_container_plant.duplicate()
			all_card_page.add_child(new_grid_container)
			all_card_page_array.append(new_grid_container)
			new_grid_container.visible = false
			## 当前页面的所有卡片占位
			card_selected_placeholder = new_grid_container.get_children()
		## 当前植物类型对应的card
		var curr_plant_card = AllCards.all_plant_card_prefabs[Global.global_game_state.curr_plant[i]]
		var new_card = curr_plant_card.duplicate()
		var card_candidate_container: CardCandidateContainer = SceneRegistry.CARD_CANDIDATE_CONTAINER.instantiate()

		card_candidate_container.init_card_in_seed_chooser(new_card)
		card_selected_placeholder[curr_plant_card.card_id % num_card_every_page].add_child(card_candidate_container)
		all_card_candidate_containers_plant[curr_plant_card.card_id] = card_candidate_container
	grid_container_plant.queue_free()

## 初始化生成僵尸待选卡槽
func _init_card_slot_candidate_zombie():
	## 每一页的卡片数量
	var num_card_every_page = grid_container_zombie.get_child_count()
	all_card_page.remove_child(grid_container_zombie)
	## 当前页面的所有卡片占位
	var card_selected_placeholder:Array
	var curr_num_page:int = -1
	for i:int in Global.global_game_state.curr_zombie.size():
		var page_i:int = int(float(i) / num_card_every_page)
		if curr_num_page < page_i:
			curr_num_page += 1
			var new_grid_container = grid_container_zombie.duplicate()
			all_card_page.add_child(new_grid_container)
			all_card_page_array.append(new_grid_container)
			new_grid_container.visible = false
			## 当前页面的所有卡片占位
			card_selected_placeholder = new_grid_container.get_children()
		## 当前僵尸类型对应的card
		var curr_zombie_card = AllCards.all_zombie_card_prefabs[Global.global_game_state.curr_zombie[i]]
		var new_card = curr_zombie_card.duplicate()
		var card_candidate_container: CardCandidateContainer = SceneRegistry.CARD_CANDIDATE_CONTAINER.instantiate()

		card_candidate_container.init_card_in_seed_chooser(new_card)
		card_selected_placeholder[curr_zombie_card.card_id % num_card_every_page].add_child(card_candidate_container)
		all_card_candidate_containers_zombie[curr_zombie_card.card_id] = card_candidate_container
	grid_container_zombie.queue_free()

## 初始化生成模仿者待选卡槽
func _init_card_slot_candidate_imitater():
	## 每一页的卡片数量
	var num_card_every_page = grid_container_plant_imitater.get_child_count()
	all_card_page_imitater.remove_child(grid_container_plant_imitater)
	## 当前页面的所有卡片占位
	var card_selected_placeholder:Array
	var curr_num_page_imitater:=-1
	for i:int in Global.global_game_state.curr_plant.size():
		var page_i:int = int(float(i) / num_card_every_page)
		if curr_num_page_imitater < page_i:
			curr_num_page_imitater += 1
			var new_grid_container = grid_container_plant_imitater.duplicate()
			all_card_page_imitater.add_child(new_grid_container)
			all_card_page_array_imitater.append(new_grid_container)
			new_grid_container.visible = false
			## 当前页面的所有卡片占位
			card_selected_placeholder = new_grid_container.get_children()
		## 当前植物类型对应的card
		var curr_plant_card = AllCards.all_plant_card_prefabs[Global.global_game_state.curr_plant[i]]
		var new_card = curr_plant_card.duplicate()
		new_card.is_imitater = true
		var card_candidate_container: CardCandidateContainer = SceneRegistry.CARD_CANDIDATE_CONTAINER.instantiate()

		card_candidate_container.init_card_in_seed_chooser(new_card)
		card_selected_placeholder[curr_plant_card.card_id % num_card_every_page].add_child(card_candidate_container)
		all_card_candidate_containers_plant_imitater[curr_plant_card.card_id] = card_candidate_container

	grid_container_plant_imitater.queue_free()


## 上一页
func _on_last_page_button_pressed() -> void:
	change_page(-1)

## 下一页
func _on_next_page_button_pressed() -> void:
	change_page(1)


func change_page(change_num:int= 1):
	all_card_page_array[curr_page].visible = false
	curr_page += change_num
	curr_page %= all_card_page_array.size()
	all_card_page_array[curr_page].visible = true


## 模仿者卡槽出现
func imitater_card_slot_appear():
	all_imitater_card.visible = true

## 模仿者卡槽隐藏
func imitater_card_slot_disappear():
	all_imitater_card.visible = false

## 模仿者卡片被选中时
func imitater_be_choosed() -> void:
	imitater_card_slot_disappear()
	card_imitater.imitater_card_be_choosed()

## 模仿者卡片被选中取消时
func imitater_be_choosed_cancel() -> void:
	card_imitater.imitater_card_be_choosed_cancal()



#region 模仿者页面翻页
func _on_imitater_last_page_button_pressed() -> void:
	change_page_imitater(-1)


func _on_imitater_next_page_button_pressed() -> void:
	change_page_imitater(1)


func change_page_imitater(change_num:int= 1):
	all_card_page_array_imitater[curr_page_imitater].visible = false
	curr_page_imitater += change_num
	curr_page_imitater %= all_card_page_array_imitater.size()
	all_card_page_array_imitater[curr_page_imitater].visible = true
#endregion
