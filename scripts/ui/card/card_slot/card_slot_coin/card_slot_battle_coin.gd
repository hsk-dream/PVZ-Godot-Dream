extends PanelContainer
## 出战卡槽
class_name CardSlotBattleCoin
## 赌狗小游戏金币卡槽

@onready var curr_coin_value: Label = $CoinLabelControl/CurrCoinValue
@onready var card_placeholder_ori: TextureRect = $CardUiList/CardPlaceholder_ori
@onready var card_ui_list: HBoxContainer = $CardUiList

@onready var label_info: Label = $CoinLabelControl/LabelInfo
@onready var next_wave_timer: Timer = $NextWaveTimer

## 当前波次
var curr_wave:int=1
## 当前波点击卡片次数
var curr_wave_card_max:int=1
## 当前波剩余卡片次数
var curr_wave_card:int=1
## 当前雪人逃跑概率
var curr_p:float=0.1

## 出战卡槽占位节点
var cards_placeholder:Array = []
## 出战卡片
var curr_cards : Array[Card]
var is_next_wave_refresh:=false
var is_end_wave:=false

func _ready() -> void:
	Global.config_service.signal_change_disappear_spare_card_placeholder.connect(judge_disappear_add_card_bar)
	update_label_info()
	Global.main_game.p_yeti_run = curr_p
	Global.global_game_state.coin_value_changed.connect(func(_new_value: int): curr_coin_value.text = str(Global.global_game_state.coin_value))

func _process(_delta: float) -> void:
	if curr_wave_card <= 0 and not is_end_wave:
		for z:Zombie020Yeti in Global.main_game.zombie_manager.all_zombies_1d:
			if not z.is_run_end and not z.is_death:
				return

		print("雪人都跑路了或者死亡了")
		next_wave()


func update_label_info():
	if is_end_wave:
		label_info.text = "当前波次:"+"最后一搏"+"\n当前波次卡片:"+str(curr_wave_card)+"\n雪人逃跑概率:"+str(curr_p)
	else:
		label_info.text = "当前波次:"+str(curr_wave)+"\n当前波次卡片:"+str(curr_wave_card)+"\n雪人逃跑概率:"+str(curr_p)

## 初始化出战卡槽，管理器调用
func init_card_slot_battle(max_choosed_card_num:int):
	curr_coin_value.text = str(Global.global_game_state.coin_value)
	for i in range(max_choosed_card_num):
		var cloned_card_placeholder = card_placeholder_ori.duplicate()
		card_ui_list.add_child(cloned_card_placeholder)

	card_placeholder_ori.free()		## 立即删除掉该节点，下面获取卡槽占位节点
	cards_placeholder = card_ui_list.get_children()
	return cards_placeholder

## 主游戏刷新卡片
func main_game_refresh_card():
	for i in range(curr_cards.size()):
		var card:Card = curr_cards[i]
		card.judge_sun_enough(int(Global.global_game_state.coin_value / 10.0))
		card.signal_card_use_end.connect(card_use_end.bind(card))
		card.set_shortcut((i+1)%10)
	judge_disappear_add_card_bar()

## 卡片种植后信号调用函数
func card_use_end(card:Card):
	## 减少阳光，卡片冷却
	Global.global_game_state.coin_value = Global.global_game_state.coin_value - card.sun_cost * 10
	#card.card_cool()
	curr_coin_value.text = str(Global.global_game_state.coin_value)
	card.judge_sun_enough(int(Global.global_game_state.coin_value / 10.0))
	curr_wave_card -= 1
	if curr_wave_card == 0:
		card.set_card_disable()
		if not is_end_wave:
			next_wave_timer.start()
	else:
		card.set_card_cool_time_start_cool(0)

	update_label_info()

func next_wave():
	print("刷新下一波")
	curr_wave += 1
	if curr_wave == 10:
		is_end_wave = true
	curr_wave_card_max += 1
	curr_wave_card = curr_wave_card_max
	if curr_p<=0.2:
		curr_p += 0.1
	elif curr_p<=0.4:
		curr_p += 0.05
	elif curr_p<=0.5:
		curr_p += 0

	Global.main_game.p_yeti_run = curr_p
	next_wave_timer.stop()
	curr_cards[0].set_card_cool_time_start_cool(0)
	EventBus.push_event("replenish_lawn_mover")
	update_label_info()
	if curr_wave == 10:
		EventBus.push_event("end_wave_zombie")

#region 控制台相关
## 是否显示多余卡槽
func judge_disappear_add_card_bar():
	## 在游戏进行阶段
	if Global.main_game.main_game_progress == MainGameManager.E_MainGameProgress.MAIN_GAME:
		if Global.config_service.disappear_spare_card_Placeholder:
			if curr_cards.size() < cards_placeholder.size():
				for i in range(curr_cards.size(), cards_placeholder.size()):
					cards_placeholder[i].visible = false
		else:
			for i in range(cards_placeholder.size()):
				cards_placeholder[i].visible = true
#endregion


func _on_next_wave_timer_timeout() -> void:
	next_wave()
	print("时间到,刷新下一波")

## 每秒触发刷新小推车
func _on_replenish_lawn_mover_timer_timeout() -> void:
	EventBus.push_event("replenish_lawn_mover")
