## 传送带和种子雨共用的卡牌权重条目；引用描述身份，权重描述相对出现概率。
extends Resource
class_name ResourceCardWeight

## 参与抽取的卡牌引用；当前只能配置允许出战的卡牌。
@export var card_reference: ResourceCardReference
## 相对权重；0 不参与抽取，负数和全部为零的池由初始化入口拒绝。
@export_range(0, 100000, 1, "or_greater") var weight: int = 1
