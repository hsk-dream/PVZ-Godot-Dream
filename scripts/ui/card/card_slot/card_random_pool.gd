## 按统一卡牌引用的权重抽取出战卡，不创建节点或修改模板。
extends Node
class_name CardRandomPool

## 可抽取的卡牌引用，顺序与权重条目一致。
var _references: Array[ResourceCardReference] = []
## 每个有效条目的累计权重上界。
var _cumulative_weights: Array[int] = []
## 有效条目的总权重；零表示没有可抽取内容。
var _total_weight: int = 0

## 使用 [param weights] 初始化；零权重不参与，负权重、僵王和无效出战引用报告错误。
## 单次抽取保留每张植物、僵尸卡的相对概率，不以类型额外分组。
func init_card_random_pool(weights: Array[ResourceCardWeight]) -> void:
	_references.clear()
	_cumulative_weights.clear()
	_total_weight = 0
	# 权重条目只读，保存独立引用以避免修改共享关卡资源。
	for entry: ResourceCardWeight in weights:
		if entry != null and entry.weight == 0:
			continue
		if entry == null or entry.weight < 0 or not AllCards.is_battle_card(entry.card_reference) \
			or entry.card_reference.card_type == ResourceCardReference.CardType.ZombieBoss:
			push_error("CardRandomPool：条目必须引用已注册的植物或普通僵尸，并具有正权重。")
			continue
		_references.append(entry.card_reference.copy_reference())
		_total_weight += entry.weight
		_cumulative_weights.append(_total_weight)
	if _total_weight == 0:
		push_error("CardRandomPool：没有可抽取的出战卡牌。")

## 返回按权重抽取的独立引用；空池返回 null，由生成入口停止本次创建。
func get_random_reference() -> ResourceCardReference:
	if _total_weight <= 0:
		return null
	# 本次随机数落入某个条目的累计权重区间。
	var random_weight: int = randi_range(1, _total_weight)
	# 累计区间索引与引用数组一一对应。
	for index: int in _cumulative_weights.size():
		if random_weight <= _cumulative_weights[index]:
			return _references[index].copy_reference()
	return null


