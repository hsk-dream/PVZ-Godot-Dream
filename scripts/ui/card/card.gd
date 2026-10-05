## 可交互卡牌；用途决定点击路径，身份与模仿修饰统一来自卡牌引用。
extends CardBase
class_name Card

## 静态缩略图容器，复制卡牌时不创建出战角色。
@onready var character_static: Node2D = $CardBg/CharacterStatic
## 卡槽快捷键文字。
@onready var short_cut: Label = $ShortCut
## 接收卡牌点击的按钮。
@onready var button: Button = $Button

## 显示用途独立于内容类型，避免图鉴被当前战斗场景接管点击。
enum CardContext {
	Catalog, ## 隐藏源目录，不处理点击。
	Selection, ## 选卡与取消选择。
	Battle, ## 交给手持管理器使用。
	Almanac, ## 打开图鉴详情。
}

## 当前实例的点击用途；创建入口应在入树前设置。
var card_context: CardContext = CardContext.Catalog
## 是否处于冷却中。
var _is_cooling: bool = false
## 当前费用是否已被卡槽判定为足够。
var is_sun_enough: bool = true
## 剩余冷却时间，单位为游戏秒。
var _cool_timer: float = 0.0
## 当前是否可以使用，由冷却、费用和种植条件共同决定。
var is_can_click: bool = true
## 临时卡消失前的闪烁补间；停止时释放引用。
var tween_blink: Tween
## 是否为关卡锁定的预选卡，选卡阶段不可取消。
var is_choosed_pre_card: bool = false
## 对应的候选占位容器，选中后用于恢复备选显示。
var card_candidate_container: CardCandidateContainer
## 模仿卡共用的着色材质，每个展示实例使用独立副本。
const IMITATER = preload("res://shader_material/imitater.tres")
## 选卡或图鉴点击通知，始终携带实际被点击的卡牌。
signal signal_card_click(card: Card)
## 内容成功放置后的结算通知，由所属卡槽或临时卡管理器消费一次。
@warning_ignore("unused_signal")
signal signal_card_use_end(card: Card)


## 初始化参数与模仿外观；展示型内容不显示费用、快捷键和冷却遮罩。
func _ready() -> void:
	super()
	_cool_mask.value = 0
	if card_reference == null or not card_reference.is_valid():
		is_can_click = false
		return
	if card_reference.card_type == ResourceCardReference.CardType.ZombieBoss:
		short_cut.hide()
		_cool_mask.hide()
	if card_reference.is_imitater:
		character_static.material = IMITATER.duplicate()
		# 静态图像的子节点继承模仿材质。
		for child: Node in character_static.get_children():
			if child is Node2D:
				GlobalUtils.node_use_parent_material(child as Node2D)


## 修改实例冷却时长；[param new_cool_time] 单位为秒，0 用于无冷却模式。
func card_change_cool_time(new_cool_time: float) -> void:
	cool_time = new_cool_time
	_cool_mask.value = 0


## 设置 [param new_cool_time] 秒冷却并立即开始计时。
func set_card_cool_time_start_cool(new_cool_time: float) -> void:
	cool_time = new_cool_time
	card_cool()


## 禁用当前卡牌但不运行冷却，用于模式限制和使用次数耗尽。
func set_card_disable() -> void:
	cool_time = 1
	_cool_mask.value = cool_time
	_is_cooling = false
	_cool_mask.visible = true
	is_can_click = false


## 传送带卡牌免费使用；在入树并完成角色参数初始化后调用。
func card_init_conveyor_belt() -> void:
	_cool_mask.value = 0
	sun_cost = 0


## 按 [param delta] 游戏秒推进已有冷却，树暂停时不执行。
func _process(delta: float) -> void:
	if _is_cooling:
		_cool_timer -= delta
		_cool_mask.value = _cool_timer
		if _cool_timer <= 0:
			_is_cooling = false
			judge_card_ready()


## 根据 [param curr_sun_value] 更新费用可用性，并重新计算是否可以使用。
func judge_sun_enough(curr_sun_value: int) -> void:
	is_sun_enough = curr_sun_value >= sun_cost
	judge_card_ready()


## 结合类别、费用、冷却和紫卡前置条件更新可用状态；非战斗卡牌不能就绪。
func judge_card_ready() -> void:
	if not AllCards.is_battle_card(card_reference):
		is_can_click = false
		return
	if not is_sun_enough or _is_cooling:
		card_not_can_click()
		return
	if is_purple_card:
		# 紫卡只可能来自植物，编号在调用种植条件时解释为植物枚举。
		var plant_type: CharacterRegistry.PlantType = card_reference.content_id
		if not plant_condition.judge_purple_card_can_plant(Global.main_game.plant_cell_manager.all_plant_cells, plant_type):
			card_not_can_click()
			return
	card_ready()


## 清空冷却状态；可用性由卡槽接下来的费用刷新决定。
func set_card_cool_end() -> void:
	_cool_timer = 0
	_cool_mask.value = 0
	_is_cooling = false


## 标记卡牌就绪并隐藏不可用遮罩。
func card_ready() -> void:
	_cool_mask.hide()
	is_can_click = true


## 标记卡牌不可用并显示遮罩。
func card_not_can_click() -> void:
	_cool_mask.show()
	is_can_click = false


## 开始当前实例的冷却，在成功使用后的结算处调用。
func card_cool() -> void:
	_is_cooling = true
	_cool_mask.show()
	_cool_timer = cool_time
	_cool_mask.value = cool_time
	is_can_click = false


## 按显式用途分发点击；战斗入口额外拒绝不支持出战的内容。
func _on_button_pressed() -> void:
	match card_context:
		CardContext.Almanac:
			signal_card_click.emit(self)
		CardContext.Selection:
			if AllCards.is_battle_card(card_reference):
				signal_card_click.emit(self)
		CardContext.Battle:
			if not is_instance_valid(Global.main_game) or Global.main_game.main_game_progress != MainGameManager.E_MainGameProgress.MAIN_GAME:
				return
			if is_can_click and AllCards.is_battle_card(card_reference):
				EventBus.push_event("main_game_click_card", [self])
			else:
				SoundManager.play_other_SFX("buzzer")


## 显示 [param i] 对应的卡槽快捷键编号；展示型内容不分配快捷键。
func set_shortcut(i: int) -> void:
	if card_reference != null and card_reference.card_type == ResourceCardReference.CardType.ZombieBoss:
		return
	short_cut.text = str(i)
	short_cut.show()


## 隐藏卡槽快捷键文字。
func set_shortcut_disappear() -> void:
	short_cut.hide()


## 启动循环闪烁；重复调用先停止旧补间。
func card_blink_start() -> void:
	if tween_blink and tween_blink.is_valid():
		tween_blink.kill()
	tween_blink = create_tween()
	tween_blink.set_loops()
	tween_blink.tween_property(card_bg, "modulate:a", 0.5, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween_blink.tween_property(card_bg, "modulate:a", 1.0, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


## 暂停当前闪烁补间。
func card_blink_pause() -> void:
	if tween_blink and tween_blink.is_running():
		tween_blink.pause()


## 恢复已暂停的闪烁补间。
func card_blink_resume() -> void:
	if tween_blink and not tween_blink.is_running():
		tween_blink.play()


## 停止并释放闪烁补间引用。
func card_blink_completely_stop() -> void:
	if tween_blink and tween_blink.is_valid():
		tween_blink.kill()
		tween_blink = null


## 恢复卡牌接收鼠标输入。
func mouse_filter_start() -> void:
	button.mouse_filter = Control.MOUSE_FILTER_PASS


## 停止卡牌接收鼠标输入，用于手持临时卡期间屏蔽其他临时卡。
func mouse_filter_stop() -> void:
	button.mouse_filter = Control.MOUSE_FILTER_IGNORE
