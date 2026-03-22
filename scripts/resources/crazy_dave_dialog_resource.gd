extends Resource
class_name CrazyDaveDialogResource
## 与戴夫一次交流内容资源文件

@export_group("本次对话的细节（每句话的列表）")
## 按顺序说话的列表
@export var dialog_detail_list:Array[CrazyDaveDialogDetailResource] = []
## 戴夫长时间存在时（商店）长时间idle自由说话的列表
@export var dialog_detail_long_time_idle_list:Array[CrazyDaveDialogDetailResource] = []
## 本次戴夫对话手上拿的所有场景预制体
@export var all_hand_itmes_scene:Array[PackedScene] = []

#region 戴夫的参数
@export_group("戴夫参数")
## 是否从下往上出现
@export var is_enter_up := false
## 离开时是否被蹦极僵尸带走
@export var is_grab := false
## 戴夫是否长时间存在，长时间存在，只有在离开当前场景才会退出窗口
@export var is_long_time_dave:= false
#endregion
