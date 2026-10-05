## 按目录顺序生成植物、普通僵尸、僵王及植物模仿卡页面，按可用角色列表筛选。
extends TextureRect
class_name CardSlotCandidate

## 普通备选页面的挂载节点。
@onready var all_card_page: Control = $AllCardPage
## 植物页面的占位布局模板。
@onready var grid_container_plant: GridContainer = $AllCardPage/GridContainerPlant
## 普通僵尸和僵王共用的占位布局模板。
@onready var grid_container_zombie: GridContainer = $AllCardPage/GridContainerZombie
## 类型、内容和模仿修饰共同确定的备选容器索引。
var candidate_containers: Dictionary[Vector3i, CardCandidateContainer] = {}
## 至少有一张已解锁卡的普通页面。
var all_show_page: Array[GridContainer] = []
## 普通页面的零起点页码。
var curr_page: int = 0
## 普通页面的页码标签。
@onready var label_page: Label = $LabelPage
## 模仿者选择弹层。
@onready var all_imitater_card: Control = %AllImitaterCard
## 模仿卡页面的挂载节点。
@onready var all_card_page_imitater: Control = $AllImitaterCard/Panel/AllCardPageImitater
## 模仿卡页面的占位布局模板。
@onready var grid_container_plant_imitater: GridContainer = $AllImitaterCard/Panel/AllCardPageImitater/GridContainerPlantImitater
## 独立模仿者入口，只负责打开弹层，不用于出战。
@onready var card_imitater: CardImitater = $ImitaterBG/CardImitater
## 至少有一张已解锁卡的模仿卡页面。
var all_show_page_imitater: Array[GridContainer] = []
## 模仿卡页面的零起点页码。
var curr_page_imitater: int = 0

## 根据目录稳定顺序分页，仅展示包含已解锁内容的页面。
func _ready() -> void:
	_create_candidate_pages(ResourceCardReference.CardType.Plant, grid_container_plant, all_card_page)
	_create_candidate_pages(ResourceCardReference.CardType.Zombie, grid_container_zombie, all_card_page)
	_create_candidate_pages(ResourceCardReference.CardType.Plant, grid_container_plant_imitater, all_card_page_imitater, true)
	if not all_show_page.is_empty():
		all_show_page[0].visible = true
	if not all_show_page_imitater.is_empty():
		all_show_page_imitater[0].visible = true
	label_page.text = "1/" + str(all_show_page.size()) if not all_show_page.is_empty() else "0/0"
	card_imitater.signal_card_click.connect(imitater_card_slot_appear)

## 使用 [param card_type] 的目录顺序复制 [param grid_template] 到 [param page_root]。
## [param imitate] 为 true 时为植物创建模仿修饰，不修改目录共享引用。
## 普通僵尸页末尾追加僵王目录，各引用保留自身类别，不受关卡自动出场类型影响。
func _create_candidate_pages(card_type: int, grid_template: GridContainer, page_root: Control, imitate: bool = false) -> void:
	# 页面容量沿用场景占位，内容编号不再承担布局索引。
	var page_capacity: int = grid_template.get_child_count()
	if page_capacity <= 0:
		push_error("CardSlotCandidate：备选页面缺少卡片占位。")
		return
	page_root.remove_child(grid_template)
	# 本批生成的页，顺序与目录顺序一致。
	var pages: Array[GridContainer] = []
	# 有效出战卡的连续布局索引，跳过独立模仿者入口。
	var card_index: int = 0
	# 本批分页的有序目录引用，僵王复用普通僵尸页面布局。
	var page_references: Array[ResourceCardReference] = AllCards.get_references(card_type)
	if card_type == ResourceCardReference.CardType.Zombie:
		page_references.append_array(AllCards.get_references(ResourceCardReference.CardType.ZombieBoss))
	# 当前源引用只读使用，混合页面也保留真实内容类别。
	for catalog_reference: ResourceCardReference in page_references:
		if not AllCards.is_battle_card(catalog_reference):
			continue
		# 模仿修饰只写入新引用。
		var reference: ResourceCardReference = catalog_reference.copy_reference()
		if imitate:
			reference.is_imitater = true
		# 当前卡片所属的零起点页；浮点除法后显式向下取整，保留分页规则。
		var page_index: int = floori(float(card_index) / page_capacity)
		if page_index >= pages.size():
			# 新页保留模板中的栅格占位，首次生成时先隐藏。
			var new_page: GridContainer = grid_template.duplicate() as GridContainer
			new_page.visible = false
			page_root.add_child(new_page)
			pages.append(new_page)
		# 卡片与占位分别保存引用，选择时仍可返回原位。
		var new_card: Card = AllCards.create_card(reference, Card.CardContext.Selection)
		if new_card == null:
			continue
		# 每张卡片对应的背景与返回位置。
		var container: CardCandidateContainer = SceneRegistry.CARD_CANDIDATE_CONTAINER.instantiate()
		container.init_card_in_seed_chooser(new_card)
		pages[page_index].get_child(card_index % page_capacity).add_child(container)
		container.visible = _is_unlocked(reference)
		candidate_containers[reference.get_selection_key()] = container
		card_index += 1
	# 只将含可见卡片的页面加入翻页范围。
	for page: GridContainer in pages:
		# 本页是否存在可展示的已解锁内容。
		var has_visible_card: bool = false
		# 场景中的单卡占位节点。
		for placeholder: Node in page.get_children():
			if placeholder.get_child_count() > 0 and (placeholder.get_child(0) as Control).visible:
				has_visible_card = true
				break
		if has_visible_card:
			if imitate:
				all_show_page_imitater.append(page)
			else:
				all_show_page.append(page)
	grid_template.queue_free()

## 返回 [param reference] 是否存在于对应类别的当前可用角色列表。
func _is_unlocked(reference: ResourceCardReference) -> bool:
	match reference.card_type:
		ResourceCardReference.CardType.Plant:
			return Global.global_game_state.curr_plant.has(reference.content_id)
		ResourceCardReference.CardType.Zombie:
			return Global.global_game_state.curr_zombie.has(reference.content_id)
		ResourceCardReference.CardType.ZombieBoss:
			return Global.global_game_state.curr_zombie_boss.has(reference.content_id)
	return false

## 查询 [param reference] 对应的普通或模仿卡容器，未生成内容返回 null。
func get_candidate(reference: ResourceCardReference) -> CardCandidateContainer:
	if reference == null:
		return null
	return candidate_containers.get(reference.get_selection_key()) as CardCandidateContainer

## 显示普通备选卡的上一页。
func _on_last_page_button_pressed() -> void:
	change_page(-1)

## 显示普通备选卡的下一页。
func _on_next_page_button_pressed() -> void:
	change_page(1)

## 按 [param change_num] 循环切换普通页面；空集合不执行切换。
func change_page(change_num: int = 1) -> void:
	if all_show_page.is_empty():
		return
	all_show_page[curr_page].visible = false
	curr_page = posmod(curr_page + change_num, all_show_page.size())
	all_show_page[curr_page].visible = true
	label_page.text = str(curr_page + 1) + "/" + str(all_show_page.size())

## [param _card] 是入口点击信号携带的卡片；仅打开模仿卡弹层。
func imitater_card_slot_appear(_card: Card) -> void:
	all_imitater_card.visible = true

## 关闭模仿卡弹层。
func imitater_card_slot_disappear() -> void:
	all_imitater_card.visible = false

## 真实模仿卡选中后关闭弹层并锁定独立入口。
func imitater_be_choosed() -> void:
	imitater_card_slot_disappear()
	card_imitater.imitater_card_be_choosed()

## 取消真实模仿卡后恢复独立入口。
func imitater_be_choosed_cancel() -> void:
	card_imitater.imitater_card_be_choosed_cancal()

## 显示模仿卡的上一页。
func _on_imitater_last_page_button_pressed() -> void:
	change_page_imitater(-1)

## 显示模仿卡的下一页。
func _on_imitater_next_page_button_pressed() -> void:
	change_page_imitater(1)

## 按 [param change_num] 循环切换模仿卡页面；没有解锁内容时不切换。
func change_page_imitater(change_num: int = 1) -> void:
	if all_show_page_imitater.is_empty():
		return
	all_show_page_imitater[curr_page_imitater].visible = false
	curr_page_imitater = posmod(curr_page_imitater + change_num, all_show_page_imitater.size())
	all_show_page_imitater[curr_page_imitater].visible = true
