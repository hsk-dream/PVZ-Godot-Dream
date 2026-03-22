extends Node2D
class_name CrazyDave

## 戴夫发疯动画设置为无法停止：
## crazy动画状态过度到idle动画时，
## 有渐变动画时，平底锅帽子会旋转360，因此跳过crazy对话时，动画结束才改变动画

@onready var animation_tree: AnimationTree = $AnimationTree

@onready var bubble_2: Panel = $SpeechBubble/Bubble2
@onready var speech_text_label: Label = $SpeechBubble/Bubble2/MarginContainer/SpeechTextLabel
@onready var dave_dialog_mouse_press_panel: DaveDialogMousePress = $DaveDialogMousePressPanel

@export var dialog_resource:CrazyDaveDialogResource
@export_group("资源文件赋值参数,初始化时更新赋值(动画使用)")
## 出现时是否从下往上出现
@export var is_enter_up := false
## 离开时是否被蹦极僵尸带走
@export var is_grab:=false
## 手上是否有展示物品（是否为展示物品动画）
@export var is_hand := false

@export_group("其余参数")
## 是否为激活状态，false戴夫退出
@export var is_activate := true
## 戴夫是否为idle状态，idle状态下，动画循环播放，需要等待用户点击
@export var is_idle:= true

## 说话时间长短，1,2,3，控制动画播放
var talk_time :int = 0
## 鼠标点击跳过的对话id
var mouse_skip_talk_id :int = -1
## 当前对话的id
var curr_talk_id :int = 0
## 是否为疯言疯语
var is_crazy := false
## 手上展示物品的容器节点，展示物品放置在该节点下
@export var hand_container: Node2D
## 当前手持物品id
var curr_hand_item_id:int = -1
## 所有手持物品道具
var all_hand_items:Array[Node2D]

## 选项节点
@onready var choose_node: Control = $ChooseNode
## 选项题目
@onready var choose_content: Label = $ChooseNode/Panel/MarginContainer/ChooseContent


@export_group("长时间存在戴夫参数（商店）")
## 开始长时间存在（戴夫开局讲完开场白之后）
var start_long_time_dave := false
## 长时间idle计时器，每10秒随机说一次话，若有与玩家交互，交互结束重新启动计时器
@onready var timer_long_time_idle: Timer = $TimerLongTimeIdle
## 说话结束信号
signal talk_end_signal
## 戴夫离场信号，离场动画最后发射该信号
signal signal_dave_leave_end
## 当前外部触发对话的id
var curr_external_trigger_talk_id

## 同意选项信号
signal signal_agree_choose
## 不同意选项信号
signal signal_disagree_choose


## 开始对话（出场动画结束时动画调用）
func start_dialog():
	if dialog_resource:
		dave_dialog_mouse_press_panel.visible = true
		for i in range(dialog_resource.dialog_detail_list.size()):
			var dialog_detail:CrazyDaveDialogDetailResource = dialog_resource.dialog_detail_list[i]
			once_dialog(dialog_detail)
			## 等待鼠标点击一次
			await dave_dialog_mouse_press_panel.signal_dave_dialog_press
			mouse_skip_talk_id = curr_talk_id

		## 讲完话之后隐藏对话气泡
		bubble_2.visible = false
		dave_dialog_mouse_press_panel.visible = false

		if not dialog_resource.is_long_time_dave:
			is_activate = false
			bubble_2.visible = false
		else:
			print("开场白结束")
			is_idle = true
			## 开场白结束后停止检测
			set_process_unhandled_input(false)
			start_long_time_dave = true
			timer_long_time_idle.timeout.connect(long_time_idle_auto_dialog)
			## 启动长时间idle检测计时器
			timer_long_time_idle.start()

	else:
		is_activate = false

#region 选项同意与否,button信号连接
func choose_agree():
	signal_agree_choose.emit()
	dave_dialog_mouse_press_panel.signal_dave_dialog_press.emit()
	choose_node.visible = false

func choose_disagree():
	signal_disagree_choose.emit()
	dave_dialog_mouse_press_panel.signal_dave_dialog_press.emit()
	choose_node.visible = false
#endregion


## 外部调用对话,如：描述商品，鼠标移动到商品上出现
func external_trigger_dialog(dialog_detail:CrazyDaveDialogDetailResource):
	## 如果此时开场白说完
	if start_long_time_dave:
		curr_external_trigger_talk_id = once_dialog(dialog_detail)

## 外部调用对话结束
func external_trigger_dialog_end():
	if curr_external_trigger_talk_id == curr_talk_id:
		is_idle = true
		## 当前索引为0表示外部未调用动画
		curr_external_trigger_talk_id = 0
		## 讲完话之后隐藏对话气泡,重新开始计时器
		bubble_2.visible = false
		timer_long_time_idle.start()


## 长时间idle自动说句屁话
func long_time_idle_auto_dialog():
	## idle状态，外部未触发对话，长时间挂机状态
	if is_idle and curr_external_trigger_talk_id == 0 and start_long_time_dave:
		var dialog_detail:CrazyDaveDialogDetailResource  = dialog_resource.dialog_detail_long_time_idle_list.pick_random()
		var talk_id = once_dialog(dialog_detail)
		## 等待开始idle动画
		await talk_end_signal
		## 如果当前交谈id和本次说话动画id一致，有可能被别的动画打断
		if talk_id == curr_talk_id:
			## 说话完成 开始idle
			## 讲完话之后隐藏对话气泡,重新开始计时器
			bubble_2.visible = false
			timer_long_time_idle.start()



## 说完当前这段话，动画调用
func _talk_end():
	is_idle = true
	talk_end_signal.emit()

## 手持物品时说完当前这段话，动画调用
func _talk_end_is_hand():
	is_idle = true
	talk_time -= 1
	if talk_time <= 0:
		talk_end_signal.emit()

## 商店戴夫描述商品
func long_time_dave_start_dialog():
	timer_long_time_idle.stop()



## 播放指定主题的对话气泡内容
## 功能说明：
## - 如果对话气泡当前不可见，则将其设为可见；
func once_dialog(dialog_detail:CrazyDaveDialogDetailResource) -> int:
	curr_talk_id += 1
	if bubble_2.visible == false:
		bubble_2.visible = true

	speech_text_label.text = dialog_detail.text
	_speech_anim_from_dialog_detail(dialog_detail)

	## 如果这句话之前有手持物品,先隐藏
	if curr_hand_item_id != -1:
		all_hand_items[curr_hand_item_id].visible = false
	## 如果有手持物品 并且 编号合法
	if is_hand and dialog_detail.hand_item_id >= 0 and dialog_detail.hand_item_id < all_hand_items.size():
		curr_hand_item_id = dialog_detail.hand_item_id
		all_hand_items[curr_hand_item_id].visible = true
	else:
		curr_hand_item_id = -1

	if dialog_detail.is_choosed:
		choose_node.visible = true

	return curr_talk_id

## 根据说话的文本，计算使用什么动画
## 如果不是crazy
## 根据文本长度，选择动画
## 小于8个字(汉字，字符，不考虑英文)smalltalk动画
## 小于16个字 mediumtalk
## 其余 blahblah
func _speech_anim_from_dialog_detail(dialog_detail:CrazyDaveDialogDetailResource):
	is_idle = false
	is_crazy = dialog_detail.is_crazy
	is_hand = dialog_detail.is_hand
	if is_crazy:
		SoundManager.play_crazy_dave_SFX("crazydavescream")
		talk_time = 0
	else:
		var text = dialog_detail.text
		if text.length() < 8:
			SoundManager.play_crazy_dave_SFX("crazydaveshort")
			talk_time = 1
		elif text.length() < 16:
			SoundManager.play_crazy_dave_SFX("crazydavelong")
			talk_time = 2
		else:
			SoundManager.play_crazy_dave_SFX("crazydaveextralong")
			talk_time = 3

## 初始化戴夫相关参数
## @param dialog_resource (CrazyDaveDialogResource) - 本次对话的戴夫资源文件。
## @param hand_node (Node) - 代码初始化戴夫时的手持物品，在该函数中添加到戴夫手中
func init_dave(curr_dialog_resource:CrazyDaveDialogResource, hand_node:Node = null) -> void:
	dialog_resource = curr_dialog_resource
	if hand_node:
		hand_container.add_child(hand_node)

	## 从场景中创建所有的手持物品
	for hand_itme_scene:PackedScene in curr_dialog_resource.all_hand_itmes_scene:
		var new_hand_item:Node2D = hand_itme_scene.instantiate()
		new_hand_item.visible = false
		hand_container.add_child(new_hand_item)
		all_hand_items.append(new_hand_item)

	## 第一句话是否手持物品
	is_hand = dialog_resource.dialog_detail_list[0].is_hand
	if is_hand and dialog_resource.dialog_detail_list[0].hand_item_id >= 0 and dialog_resource.dialog_detail_list[0].hand_item_id < all_hand_items.size():
		curr_hand_item_id = dialog_resource.dialog_detail_list[0].hand_item_id
		all_hand_items[curr_hand_item_id].visible = true

	is_enter_up = dialog_resource.is_enter_up
	is_grab = dialog_resource.is_grab


func reset_dave(new_dialog_resource:CrazyDaveDialogResource, hand_node:Node = null) -> void:
	## 重新播放动画
	animation_tree.set("parameters/playback", null)  # 断开当前播放
	animation_tree.active = false  # 停止播放
	animation_tree.active = true   # 重启播放

	## 是否为激活状态，false戴夫退出
	is_activate = true
	## 戴夫是否为idle状态，idle状态下，动画循环播放，需要等待用户点击
	is_idle= true
	## 说话时间长短，1,2,3，控制动画播放
	talk_time = 0
	## 鼠标点击跳过的对话id
	mouse_skip_talk_id = -1
	## 当前对话的id
	curr_talk_id = 0
	## 是否为疯言疯语
	is_crazy = false
	## 开始长时间存在（戴夫开局讲完开场白之后）
	start_long_time_dave = false
	init_dave(new_dialog_resource, hand_node)

## 戴夫离场
func dave_leave_end():
	signal_dave_leave_end.emit()
