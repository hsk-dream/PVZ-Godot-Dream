extends Goods
class_name GoodsGardenSrpout


## 获得该商品的作用，子类重写
func get_one_goods():
	Global.global_game_state.curr_num_new_garden_plant += 1
