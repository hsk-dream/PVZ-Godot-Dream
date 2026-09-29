extends Node
class_name CharacterRegistry


## 定义枚举
enum CharacterType {Null, Plant, Zombie, ZombieBoss}

#region 植物
## 植物信息属性
enum PlantInfoAttribute{
	PlantName,
	CoolTime,		## 植物种植冷却时间
	SunCost,		## 阳光消耗
	PlantScenes,	## 植物场景预加载
	PlantConditionResource,	## 植物种植条件资源预加载
}

## 植物类型
enum PlantType {
	Null = 0,
	P001PeaShooterSingle = 1,
	P002SunFlower,
	P003CherryBomb,
	P004WallNut,
	P005PotatoMine,
	P006SnowPea,
	P007Chomper,
	P008PeaShooterDouble,

	P009PuffShroom,
	P010SunShroom,
	P011FumeShroom,
	P012GraveBuster,
	P013HypnoShroom,
	P014ScaredyShroom,
	P015IceShroom,
	P016DoomShroom,

	P017LilyPad,
	P018Squash,
	P019ThreePeater,
	P020TangleKelp,
	P021Jalapeno,
	P022Caltrop,
	P023TorchWood,
	P024TallNut,

	P025SeaShroom,
	P026Plantern,
	P027Cactus,
	P028Blover,
	P029SplitPea,
	P030StarFruit,
	P031Pumpkin,
	P032MagnetShroom,

	P033CabbagePult,
	P034FlowerPot,
	P035CornPult,
	P036CoffeeBean,
	P037Garlic,
	P038UmbrellaLeaf,
	P039MariGold,
	P040MelonPult,

	P041GatlingPea,
	P042TwinSunFlower,
	P043GloomShroom,
	P044Cattail,
	P045WinterMelon,
	P046GoldMagnet,
	P047SpikeRock,
	P048CobCannon,

	P049PeaShooterDoubleReverse,

	## 模仿者
	P999Imitater = 999,
	## 发芽
	P1000Sprout = 1000,
	## 保龄球
	P1001WallNutBowling = 1001,
	P1002WallNutBowlingBomb,
	P1003WallNutBowlingBig,
	}


## 植物在格子中的位置
enum PlacePlantInCell{
	Norm,	## 普通位置
	Shell,	## 保护壳位置
	Down,	## 花盆（睡莲）位置
	Float,	## 漂浮位置
	Imitater,## 模仿者位置
}

#endregion

#region 僵尸
## 僵尸类型
enum ZombieType {
	Null = 0,

	Z001Norm = 1,
	Z002Flag,
	Z003Cone,
	Z004PoleVaulter,
	Z005Bucket,

	Z006Paper,
	Z007ScreenDoor,
	Z008Football,
	Z009Jackson,
	Z010Dancer,

	Z011Duckytube,
	Z012Snorkle,
	Z013Zamboni,
	Z014Bobsled,
	Z015Dolphinrider,

	Z016Jackbox,
	Z017Balloon,
	Z018Digger,
	Z019Pogo,
	Z020Yeti,

	Z021Bungi,
	Z022Ladder,
	Z023Catapult,
	Z024Gargantuar,
	Z025Imp,

	Z1001BobsledSingle=1001,	## 单个雪橇车僵尸
	}

## 僵尸行类型
enum ZombieRowType{
	Land,
	Pool,
	Both,
}

## 僵尸信息属性
enum ZombieInfoAttribute{
	ZombieName,
	CoolTime,		## 僵尸冷却时间
	SunCost,		## 阳光消耗
	ZombieScenes,	## 植物场景预加载
	ZombieRowType,	## 僵尸行类型
}


#endregion


#region 植物种植信息
## 紫卡植物种植前置植物
@export var AllPrePlantPurple:Dictionary[PlantType, PlantType]= {
	PlantType.P041GatlingPea:PlantType.P008PeaShooterDouble,
	PlantType.P042TwinSunFlower:PlantType.P002SunFlower,
	PlantType.P043GloomShroom:PlantType.P011FumeShroom,
	PlantType.P044Cattail:PlantType.P017LilyPad,
	PlantType.P045WinterMelon:PlantType.P040MelonPult,
	PlantType.P046GoldMagnet:PlantType.P032MagnetShroom,
	PlantType.P047SpikeRock:PlantType.P022Caltrop,
	PlantType.P048CobCannon:PlantType.P035CornPult,
}

const PlantInfo = {
	PlantType.P001PeaShooterSingle: {
		PlantInfoAttribute.PlantName: "PeaShooterSingle",
		PlantInfoAttribute.CoolTime: 7.5,
		PlantInfoAttribute.SunCost: 100,
		PlantInfoAttribute.PlantConditionResource:preload("res://resources/character_resource/plant_condition/000_common_plant_land.tres"),
		PlantInfoAttribute.PlantScenes : preload("res://scenes/character/plant/plant_001_pea_shooter_single.tscn")
		},
	PlantType.P002SunFlower: {
		PlantInfoAttribute.PlantName: "SunFlower",
		PlantInfoAttribute.CoolTime: 7.5,
		PlantInfoAttribute.SunCost: 50,
		PlantInfoAttribute.PlantConditionResource:preload("res://resources/character_resource/plant_condition/000_common_plant_land.tres"),
		PlantInfoAttribute.PlantScenes : preload("res://scenes/character/plant/plant_002_sun_flower.tscn")
		},
	PlantType.P003CherryBomb: {
		PlantInfoAttribute.PlantName: "CherryBomb",
		PlantInfoAttribute.CoolTime: 50.0,
		PlantInfoAttribute.SunCost: 150,
		PlantInfoAttribute.PlantConditionResource : preload("res://resources/character_resource/plant_condition/000_common_plant_land.tres"),
		PlantInfoAttribute.PlantScenes : preload("res://scenes/character/plant/plant_003_cherry_bomb.tscn")
		},
	PlantType.P004WallNut: {
		PlantInfoAttribute.PlantName: "WallNut",
		PlantInfoAttribute.CoolTime: 30.0,
		PlantInfoAttribute.SunCost: 50,
		PlantInfoAttribute.PlantConditionResource : preload("res://resources/character_resource/plant_condition/000_common_plant_land.tres"),
		PlantInfoAttribute.PlantScenes : preload("res://scenes/character/plant/plant_004_wall_nut.tscn")
		},
	PlantType.P005PotatoMine: {
		PlantInfoAttribute.PlantName: "PotatoMine",
		PlantInfoAttribute.CoolTime: 30.0,
		PlantInfoAttribute.SunCost: 25,
		PlantInfoAttribute.PlantConditionResource : preload("res://resources/character_resource/plant_condition/005_potato_mine.tres"),
		PlantInfoAttribute.PlantScenes : preload("res://scenes/character/plant/plant_005_potato_mine.tscn")
		},
	PlantType.P006SnowPea: {
		PlantInfoAttribute.PlantName: "SnowPea",
		PlantInfoAttribute.CoolTime: 7.5,
		PlantInfoAttribute.SunCost: 175,
		PlantInfoAttribute.PlantConditionResource : preload("res://resources/character_resource/plant_condition/000_common_plant_land.tres"),
		PlantInfoAttribute.PlantScenes : preload("res://scenes/character/plant/plant_006_snow_pea.tscn")
		},
	PlantType.P007Chomper: {
		PlantInfoAttribute.PlantName: "Chomper",
		PlantInfoAttribute.CoolTime: 7.5,
		PlantInfoAttribute.SunCost: 150,
		PlantInfoAttribute.PlantConditionResource : preload("res://resources/character_resource/plant_condition/000_common_plant_land.tres"),
		PlantInfoAttribute.PlantScenes : preload("res://scenes/character/plant/plant_007_chomper.tscn")
		},
	PlantType.P008PeaShooterDouble: {
		PlantInfoAttribute.PlantName: "PeaShooterDouble",
		PlantInfoAttribute.CoolTime: 7.5,
		PlantInfoAttribute.SunCost: 200,
		PlantInfoAttribute.PlantConditionResource : preload("res://resources/character_resource/plant_condition/000_common_plant_land.tres"),
		PlantInfoAttribute.PlantScenes : preload("res://scenes/character/plant/plant_008_pea_shooter_double.tscn")
		},
		#
	PlantType.P009PuffShroom: {
		PlantInfoAttribute.PlantName: "PuffShroom",
		PlantInfoAttribute.CoolTime: 7.5,
		PlantInfoAttribute.SunCost: 0,
		PlantInfoAttribute.PlantConditionResource : preload("res://resources/character_resource/plant_condition/000_common_plant_land.tres"),
		PlantInfoAttribute.PlantScenes : preload("res://scenes/character/plant/plant_009_puff.tscn")
		},
	PlantType.P010SunShroom: {
		PlantInfoAttribute.PlantName: "SunShroom",
		PlantInfoAttribute.CoolTime: 7.5,
		PlantInfoAttribute.SunCost: 25,
		PlantInfoAttribute.PlantConditionResource : preload("res://resources/character_resource/plant_condition/000_common_plant_land.tres"),
		PlantInfoAttribute.PlantScenes : preload("res://scenes/character/plant/plant_010_sun_shroom.tscn")
		},
	PlantType.P011FumeShroom: {
		PlantInfoAttribute.PlantName: "FumeShroom",
		PlantInfoAttribute.CoolTime: 7.5,
		PlantInfoAttribute.SunCost: 75,
		PlantInfoAttribute.PlantConditionResource : preload("res://resources/character_resource/plant_condition/000_common_plant_land.tres"),
		PlantInfoAttribute.PlantScenes : preload("res://scenes/character/plant/plant_011_fume_shroom.tscn")
		},
	PlantType.P012GraveBuster: {
		PlantInfoAttribute.PlantName: "GraveBuster",
		PlantInfoAttribute.CoolTime: 7.5,
		PlantInfoAttribute.SunCost: 75,
		PlantInfoAttribute.PlantConditionResource : preload("res://resources/character_resource/plant_condition/012_grave_buster.tres"),
		PlantInfoAttribute.PlantScenes : preload("res://scenes/character/plant/plant_012_grave_buster.tscn")
		},
	PlantType.P013HypnoShroom: {
		PlantInfoAttribute.PlantName: "HypnoShroom",
		PlantInfoAttribute.CoolTime: 30.0,
		PlantInfoAttribute.SunCost: 75,
		PlantInfoAttribute.PlantConditionResource : preload("res://resources/character_resource/plant_condition/000_common_plant_land.tres"),
		PlantInfoAttribute.PlantScenes : preload("res://scenes/character/plant/plant_013_hypno_shroom.tscn")
		},
	PlantType.P014ScaredyShroom: {
		PlantInfoAttribute.PlantName: "ScaredyShroom",
		PlantInfoAttribute.CoolTime: 7.5,
		PlantInfoAttribute.SunCost: 25,
		PlantInfoAttribute.PlantConditionResource : preload("res://resources/character_resource/plant_condition/000_common_plant_land.tres"),
		PlantInfoAttribute.PlantScenes : preload("res://scenes/character/plant/plant_014_scaredy_shroom.tscn")
		},
	PlantType.P015IceShroom: {
		PlantInfoAttribute.PlantName: "IceShroom",
		PlantInfoAttribute.CoolTime: 50.0,
		PlantInfoAttribute.SunCost: 75,
		PlantInfoAttribute.PlantConditionResource : preload("res://resources/character_resource/plant_condition/000_common_plant_land.tres"),
		PlantInfoAttribute.PlantScenes : preload("res://scenes/character/plant/plant_015_ice_shroom.tscn")
		},
	PlantType.P016DoomShroom: {
		PlantInfoAttribute.PlantName: "DoomShroom",
		PlantInfoAttribute.CoolTime: 50.0,
		PlantInfoAttribute.SunCost: 125,
		PlantInfoAttribute.PlantConditionResource : preload("res://resources/character_resource/plant_condition/000_common_plant_land.tres"),
		PlantInfoAttribute.PlantScenes : preload("res://scenes/character/plant/plant_016_doom_shroom.tscn")
		},
	PlantType.P017LilyPad: {
		PlantInfoAttribute.PlantName: "LilyPad",
		PlantInfoAttribute.CoolTime: 7.5,
		PlantInfoAttribute.SunCost: 25,
		PlantInfoAttribute.PlantConditionResource : preload("res://resources/character_resource/plant_condition/017_lily_pad.tres"),
		PlantInfoAttribute.PlantScenes : preload("res://scenes/character/plant/plant_017_lily_pad.tscn")
		},
	PlantType.P018Squash: {
		PlantInfoAttribute.PlantName: "Squash",
		PlantInfoAttribute.CoolTime: 30.0,
		PlantInfoAttribute.SunCost: 50,
		PlantInfoAttribute.PlantConditionResource : preload("res://resources/character_resource/plant_condition/000_common_plant_land.tres"),
		PlantInfoAttribute.PlantScenes : preload("res://scenes/character/plant/plant_018_squash.tscn")
		},
	PlantType.P019ThreePeater: {
		PlantInfoAttribute.PlantName: "ThreePeater",
		PlantInfoAttribute.CoolTime: 7.5,
		PlantInfoAttribute.SunCost: 325,
		PlantInfoAttribute.PlantConditionResource : preload("res://resources/character_resource/plant_condition/000_common_plant_land.tres"),
		PlantInfoAttribute.PlantScenes : preload("res://scenes/character/plant/plant_019_three_peater.tscn")
		},
	PlantType.P020TangleKelp: {
		PlantInfoAttribute.PlantName: "TangleKelp",
		PlantInfoAttribute.CoolTime: 30.0,
		PlantInfoAttribute.SunCost: 25,
		PlantInfoAttribute.PlantConditionResource : preload("res://resources/character_resource/plant_condition/020_tanglekelp.tres"),
		PlantInfoAttribute.PlantScenes : preload("res://scenes/character/plant/plant_020_tanglekelp.tscn")
		},
	PlantType.P021Jalapeno: {
		PlantInfoAttribute.PlantName: "Jalapeno",
		PlantInfoAttribute.CoolTime: 50.0,
		PlantInfoAttribute.SunCost: 125,
		PlantInfoAttribute.PlantConditionResource : preload("res://resources/character_resource/plant_condition/000_common_plant_land.tres"),
		PlantInfoAttribute.PlantScenes : preload("res://scenes/character/plant/plant_021_jalapeno.tscn")
		},
	PlantType.P022Caltrop: {
		PlantInfoAttribute.PlantName: "Caltrop",
		PlantInfoAttribute.CoolTime: 7.5,
		PlantInfoAttribute.SunCost: 125,
		PlantInfoAttribute.PlantConditionResource : preload("res://resources/character_resource/plant_condition/022_caltrop.tres"),
		PlantInfoAttribute.PlantScenes : preload("res://scenes/character/plant/plant_022_caltrop.tscn")
		},
	PlantType.P023TorchWood: {
		PlantInfoAttribute.PlantName: "TorchWood",
		PlantInfoAttribute.CoolTime: 7.5,
		PlantInfoAttribute.SunCost: 175,
		PlantInfoAttribute.PlantConditionResource : preload("res://resources/character_resource/plant_condition/000_common_plant_land.tres"),
		PlantInfoAttribute.PlantScenes : preload("res://scenes/character/plant/plant_023_torch_wood.tscn")
		},
	PlantType.P024TallNut: {
		PlantInfoAttribute.PlantName: "TallNut",
		PlantInfoAttribute.CoolTime: 30.0,
		PlantInfoAttribute.SunCost: 175,
		PlantInfoAttribute.PlantConditionResource : preload("res://resources/character_resource/plant_condition/000_common_plant_land.tres"),
		PlantInfoAttribute.PlantScenes : preload("res://scenes/character/plant/plant_024_tall_nut.tscn")
		},

	PlantType.P025SeaShroom: {
		PlantInfoAttribute.PlantName: "SeaShroom",
		PlantInfoAttribute.CoolTime: 30.0,
		PlantInfoAttribute.SunCost: 0,
		PlantInfoAttribute.PlantConditionResource : preload("res://resources/character_resource/plant_condition/020_tanglekelp.tres"),
		PlantInfoAttribute.PlantScenes : preload("res://scenes/character/plant/plant_025_sea_shroom.tscn")
		},
	PlantType.P026Plantern: {
		PlantInfoAttribute.PlantName: "Plantern",
		PlantInfoAttribute.CoolTime: 30.0,
		PlantInfoAttribute.SunCost: 25,
		PlantInfoAttribute.PlantConditionResource : preload("res://resources/character_resource/plant_condition/000_common_plant_land.tres"),
		PlantInfoAttribute.PlantScenes : preload("res://scenes/character/plant/plant_026_plantern.tscn")
		},
	PlantType.P027Cactus: {
		PlantInfoAttribute.PlantName: "Cactus",
		PlantInfoAttribute.CoolTime: 7.5,
		PlantInfoAttribute.SunCost: 125,
		PlantInfoAttribute.PlantConditionResource :  preload("res://resources/character_resource/plant_condition/000_common_plant_land.tres"),
		PlantInfoAttribute.PlantScenes : preload("res://scenes/character/plant/plant_027_cactus.tscn")
		},
	PlantType.P028Blover: {
		PlantInfoAttribute.PlantName: "Blover",
		PlantInfoAttribute.CoolTime: 7.5,
		PlantInfoAttribute.SunCost: 100,
		PlantInfoAttribute.PlantConditionResource :  preload("res://resources/character_resource/plant_condition/000_common_plant_land.tres"),
		PlantInfoAttribute.PlantScenes : preload("res://scenes/character/plant/plant_028_blover.tscn")
		},
	PlantType.P029SplitPea: {
		PlantInfoAttribute.PlantName: "SplitPea",
		PlantInfoAttribute.CoolTime: 7.5,
		PlantInfoAttribute.SunCost: 125,
		PlantInfoAttribute.PlantConditionResource :  preload("res://resources/character_resource/plant_condition/000_common_plant_land.tres"),
		PlantInfoAttribute.PlantScenes : preload("res://scenes/character/plant/plant_029_split_pea.tscn")
		},
	PlantType.P030StarFruit: {
		PlantInfoAttribute.PlantName: "StarFruit",
		PlantInfoAttribute.CoolTime: 7.5,
		PlantInfoAttribute.SunCost: 125,
		PlantInfoAttribute.PlantConditionResource :  preload("res://resources/character_resource/plant_condition/000_common_plant_land.tres"),
		PlantInfoAttribute.PlantScenes : preload("res://scenes/character/plant/plant_030_star_fruit.tscn")
		},
	PlantType.P031Pumpkin: {
		PlantInfoAttribute.PlantName: "Pumpkin",
		PlantInfoAttribute.CoolTime: 30.0,
		PlantInfoAttribute.SunCost: 125,
		PlantInfoAttribute.PlantConditionResource :  preload("res://resources/character_resource/plant_condition/031_Pumpkin.tres"),
		PlantInfoAttribute.PlantScenes : preload("res://scenes/character/plant/plant_031_pumpkin.tscn")
		},
	PlantType.P032MagnetShroom: {
		PlantInfoAttribute.PlantName: "MagnetShroom",
		PlantInfoAttribute.CoolTime: 7.5,
		PlantInfoAttribute.SunCost: 100,
		PlantInfoAttribute.PlantConditionResource :  preload("res://resources/character_resource/plant_condition/000_common_plant_land.tres"),
		PlantInfoAttribute.PlantScenes : preload("res://scenes/character/plant/plant_032_magnet_shroom.tscn")
		},

	PlantType.P033CabbagePult: {
		PlantInfoAttribute.PlantName: "CabbagePult",
		PlantInfoAttribute.CoolTime: 7.5,
		PlantInfoAttribute.SunCost: 100,
		PlantInfoAttribute.PlantConditionResource :  preload("res://resources/character_resource/plant_condition/000_common_plant_land.tres"),
		PlantInfoAttribute.PlantScenes : preload("res://scenes/character/plant/plant_033_cabbage_pult.tscn")
		},
	PlantType.P034FlowerPot: {
		PlantInfoAttribute.PlantName: "FlowerPot",
		PlantInfoAttribute.CoolTime: 7.5,
		PlantInfoAttribute.SunCost: 25,
		PlantInfoAttribute.PlantConditionResource :  preload("res://resources/character_resource/plant_condition/034_flower_pot.tres"),
		PlantInfoAttribute.PlantScenes : preload("res://scenes/character/plant/plant_034_flower_pot.tscn")
		},
	PlantType.P035CornPult: {
		PlantInfoAttribute.PlantName: "CornPult",
		PlantInfoAttribute.CoolTime: 7.5,
		PlantInfoAttribute.SunCost: 125,
		PlantInfoAttribute.PlantConditionResource :  preload("res://resources/character_resource/plant_condition/000_common_plant_land.tres"),
		PlantInfoAttribute.PlantScenes : preload("res://scenes/character/plant/plant_035_corn_pult.tscn")
		},
	PlantType.P036CoffeeBean: {
		PlantInfoAttribute.PlantName: "CoffeeBean",
		PlantInfoAttribute.CoolTime: 7.5,
		PlantInfoAttribute.SunCost: 75,
		PlantInfoAttribute.PlantConditionResource :  preload("res://resources/character_resource/plant_condition/036_coffee_bean.tres"),
		PlantInfoAttribute.PlantScenes : preload("res://scenes/character/plant/plant_036_coffee_bean.tscn")
		},
	PlantType.P037Garlic: {
		PlantInfoAttribute.PlantName: "Garlic",
		PlantInfoAttribute.CoolTime: 7.5,
		PlantInfoAttribute.SunCost: 50,
		PlantInfoAttribute.PlantConditionResource :  preload("res://resources/character_resource/plant_condition/000_common_plant_land.tres"),
		PlantInfoAttribute.PlantScenes : preload("res://scenes/character/plant/plant_037_garlic.tscn")
		},
	PlantType.P038UmbrellaLeaf: {
		PlantInfoAttribute.PlantName: "UmbrellaLeaf",
		PlantInfoAttribute.CoolTime: 7.5,
		PlantInfoAttribute.SunCost: 100,
		PlantInfoAttribute.PlantConditionResource :  preload("res://resources/character_resource/plant_condition/000_common_plant_land.tres"),
		PlantInfoAttribute.PlantScenes : preload("res://scenes/character/plant/plant_038_umbrella_leaf.tscn")
		},
	PlantType.P039MariGold: {
		PlantInfoAttribute.PlantName: "MariGold",
		PlantInfoAttribute.CoolTime: 30.0,
		PlantInfoAttribute.SunCost: 50,
		PlantInfoAttribute.PlantConditionResource :  preload("res://resources/character_resource/plant_condition/000_common_plant_land.tres"),
		PlantInfoAttribute.PlantScenes : preload("res://scenes/character/plant/plant_039_mari_gold.tscn")
		},
	PlantType.P040MelonPult: {
		PlantInfoAttribute.PlantName: "MelonPult",
		PlantInfoAttribute.CoolTime: 7.5,
		PlantInfoAttribute.SunCost: 300,
		PlantInfoAttribute.PlantConditionResource :  preload("res://resources/character_resource/plant_condition/000_common_plant_land.tres"),
		PlantInfoAttribute.PlantScenes : preload("res://scenes/character/plant/plant_040_melon_pult.tscn")
		},

	PlantType.P041GatlingPea: {
		PlantInfoAttribute.PlantName: "GatlingPea",
		PlantInfoAttribute.CoolTime: 50.0,
		PlantInfoAttribute.SunCost: 250,
		PlantInfoAttribute.PlantConditionResource : preload("res://resources/character_resource/plant_condition/000_common_purple.tres"),
		PlantInfoAttribute.PlantScenes : preload("res://scenes/character/plant/plant_041_gatling_pea.tscn")
		},

	PlantType.P042TwinSunFlower: {
		PlantInfoAttribute.PlantName: "TwinSunFlower",
		PlantInfoAttribute.CoolTime: 50.0,
		PlantInfoAttribute.SunCost: 150,
		PlantInfoAttribute.PlantConditionResource : preload("res://resources/character_resource/plant_condition/000_common_purple.tres"),
		PlantInfoAttribute.PlantScenes : preload("res://scenes/character/plant/plant_042_twin_sun_flower.tscn")
		},

	PlantType.P043GloomShroom: {
		PlantInfoAttribute.PlantName: "GloomShroom",
		PlantInfoAttribute.CoolTime: 50.0,
		PlantInfoAttribute.SunCost: 150,
		PlantInfoAttribute.PlantConditionResource : preload("res://resources/character_resource/plant_condition/000_common_purple.tres"),
		PlantInfoAttribute.PlantScenes : preload("res://scenes/character/plant/plant_043_gloom_shroom.tscn")
		},

	PlantType.P044Cattail: {
		PlantInfoAttribute.PlantName: "Cattail",
		PlantInfoAttribute.CoolTime: 50.0,
		PlantInfoAttribute.SunCost: 225,
		PlantInfoAttribute.PlantConditionResource : preload("res://resources/character_resource/plant_condition/000_common_purple.tres"),
		PlantInfoAttribute.PlantScenes : preload("res://scenes/character/plant/plant_044_cattail.tscn")
		},

	PlantType.P045WinterMelon: {
		PlantInfoAttribute.PlantName: "WinterMelon",
		PlantInfoAttribute.CoolTime: 50.0,
		PlantInfoAttribute.SunCost: 200,
		PlantInfoAttribute.PlantConditionResource : preload("res://resources/character_resource/plant_condition/000_common_purple.tres"),
		PlantInfoAttribute.PlantScenes : preload("res://scenes/character/plant/plant_045_winter_melon.tscn")
		},

	PlantType.P046GoldMagnet: {
		PlantInfoAttribute.PlantName: "GoldMagnet",
		PlantInfoAttribute.CoolTime: 50.0,
		PlantInfoAttribute.SunCost: 50,
		PlantInfoAttribute.PlantConditionResource : preload("res://resources/character_resource/plant_condition/000_common_purple.tres"),
		PlantInfoAttribute.PlantScenes : preload("res://scenes/character/plant/plant_046_gold_magnet.tscn")
		},

	PlantType.P047SpikeRock: {
		PlantInfoAttribute.PlantName: "SpikeRock",
		PlantInfoAttribute.CoolTime: 50.0,
		PlantInfoAttribute.SunCost: 125,
		PlantInfoAttribute.PlantConditionResource : preload("res://resources/character_resource/plant_condition/000_common_purple.tres"),
		PlantInfoAttribute.PlantScenes : preload("res://scenes/character/plant/plant_047_spike_rock.tscn")
		},

	PlantType.P048CobCannon: {
		PlantInfoAttribute.PlantName: "CobCannon",
		PlantInfoAttribute.CoolTime: 50.0,
		PlantInfoAttribute.SunCost: 500,
		PlantInfoAttribute.PlantConditionResource : preload("res://resources/character_resource/plant_condition/048_cob_cannon.tres"),
		PlantInfoAttribute.PlantScenes : preload("res://scenes/character/plant/plant_048_cob_cannon.tscn")
		},

	PlantType.P049PeaShooterDoubleReverse: {
		PlantInfoAttribute.PlantName: "PeaShooterDoubleReverse",
		PlantInfoAttribute.CoolTime: 7.5,
		PlantInfoAttribute.SunCost: 200,
		PlantInfoAttribute.PlantConditionResource : preload("res://resources/character_resource/plant_condition/000_common_plant_land.tres"),
		PlantInfoAttribute.PlantScenes : preload("res://scenes/character/plant/plant_049_pea_shooter_double_reverse.tscn")
		},

	## 模仿者
	PlantType.P999Imitater:{
		PlantInfoAttribute.PlantName: "Imitater",
		PlantInfoAttribute.CoolTime: 50.0,
		PlantInfoAttribute.SunCost: 0,
		PlantInfoAttribute.PlantConditionResource :  preload("res://resources/character_resource/plant_condition/999_imitater.tres"),
		PlantInfoAttribute.PlantScenes :  preload("res://scenes/character/plant/plant_999_imitater.tscn")
		},


	## 发芽
	PlantType.P1000Sprout:{
		PlantInfoAttribute.PlantName: "Sprout",
		PlantInfoAttribute.CoolTime: 7.5,
		PlantInfoAttribute.SunCost: 50,
		PlantInfoAttribute.PlantConditionResource :  preload("res://resources/character_resource/plant_condition/000_common_plant_land.tres"),
		PlantInfoAttribute.PlantScenes :  preload("res://scenes/character/plant/plant_1000_sprout.tscn")
		},

	## 保龄球
	PlantType.P1001WallNutBowling: {
		PlantInfoAttribute.PlantName: "WallNutBowling",
		PlantInfoAttribute.CoolTime: 7.5,
		PlantInfoAttribute.SunCost: 50,
		PlantInfoAttribute.PlantConditionResource :  preload("res://resources/character_resource/plant_condition/000_common_plant_land.tres"),
		PlantInfoAttribute.PlantScenes :  preload("res://scenes/character/plant/plant_1001_wall_nut_bowling.tscn")
		},
	PlantType.P1002WallNutBowlingBomb: {
		PlantInfoAttribute.PlantName: "WallNutBowlingBomb",
		PlantInfoAttribute.CoolTime: 7.5,
		PlantInfoAttribute.SunCost: 50,
		PlantInfoAttribute.PlantConditionResource :  preload("res://resources/character_resource/plant_condition/000_common_plant_land.tres"),
		PlantInfoAttribute.PlantScenes :  preload("res://scenes/character/plant/plant_1002_wall_nut_bowling.tscn")
		},
	PlantType.P1003WallNutBowlingBig: {
		PlantInfoAttribute.PlantName: "WallNutBowlingBig",
		PlantInfoAttribute.CoolTime: 7.5,
		PlantInfoAttribute.SunCost: 50,
		PlantInfoAttribute.PlantConditionResource : preload("res://resources/character_resource/plant_condition/000_common_plant_land.tres"),
		PlantInfoAttribute.PlantScenes : preload("res://scenes/character/plant/plant_1003_wall_nut_bowling.tscn")
		},
}


## 获取植物属性方法
func get_plant_info(plant_type:PlantType, info_attribute:PlantInfoAttribute):
	if plant_type == PlantType.Null:
		print("warning:获取空植物信息")
		return null
	var curr_plant_info = PlantInfo[plant_type]
	return curr_plant_info[info_attribute]

#endregion

#region 僵尸
## 僵尸信息
const ZombieInfo = {
	ZombieType.Z001Norm:{
		ZombieInfoAttribute.ZombieName: "ZombieNorm",
		ZombieInfoAttribute.CoolTime: 0.0,
		ZombieInfoAttribute.SunCost: 50,
		ZombieInfoAttribute.ZombieScenes:preload("res://scenes/character/zombie/zombie_001_norm.tscn"),
		ZombieInfoAttribute.ZombieRowType:CharacterRegistry.ZombieRowType.Both
	},
	ZombieType.Z002Flag:{
		ZombieInfoAttribute.ZombieName: "ZombieFlag",
		ZombieInfoAttribute.CoolTime: 0.0,
		ZombieInfoAttribute.SunCost: 50,
		ZombieInfoAttribute.ZombieScenes:preload("res://scenes/character/zombie/zombie_002_flag.tscn"),
		ZombieInfoAttribute.ZombieRowType:CharacterRegistry.ZombieRowType.Both
	},
	ZombieType.Z003Cone:{
		ZombieInfoAttribute.ZombieName: "ZombieCone",
		ZombieInfoAttribute.CoolTime: 0.0,
		ZombieInfoAttribute.SunCost: 75,
		ZombieInfoAttribute.ZombieScenes:preload("res://scenes/character/zombie/zombie_003_cone.tscn"),
		ZombieInfoAttribute.ZombieRowType:CharacterRegistry.ZombieRowType.Both
	},
	ZombieType.Z004PoleVaulter:{
		ZombieInfoAttribute.ZombieName: "ZombiePoleVaulter",
		ZombieInfoAttribute.CoolTime: 0.0,
		ZombieInfoAttribute.SunCost: 75,
		ZombieInfoAttribute.ZombieScenes:preload("res://scenes/character/zombie/zombie_004_pole_vaulter.tscn"),
		ZombieInfoAttribute.ZombieRowType:CharacterRegistry.ZombieRowType.Land
	},
	ZombieType.Z005Bucket:{
		ZombieInfoAttribute.ZombieName: "ZombieBucket",
		ZombieInfoAttribute.CoolTime: 0.0,
		ZombieInfoAttribute.SunCost: 125,
		ZombieInfoAttribute.ZombieScenes:preload("res://scenes/character/zombie/zombie_005_bucket.tscn"),
		ZombieInfoAttribute.ZombieRowType:CharacterRegistry.ZombieRowType.Both
	},

	ZombieType.Z006Paper:{
		ZombieInfoAttribute.ZombieName: "ZombiePaper",
		ZombieInfoAttribute.CoolTime: 0.0,
		ZombieInfoAttribute.SunCost: 125,
		ZombieInfoAttribute.ZombieScenes:preload("res://scenes/character/zombie/zombie_006_paper.tscn"),
		ZombieInfoAttribute.ZombieRowType:CharacterRegistry.ZombieRowType.Land
	},
	ZombieType.Z007ScreenDoor:{
		ZombieInfoAttribute.ZombieName: "ZombieScreenDoor",
		ZombieInfoAttribute.CoolTime: 0.0,
		ZombieInfoAttribute.SunCost: 125,
		ZombieInfoAttribute.ZombieScenes:preload("res://scenes/character/zombie/zombie_007_screendoor.tscn"),
		ZombieInfoAttribute.ZombieRowType:CharacterRegistry.ZombieRowType.Land
	},
	ZombieType.Z008Football:{
		ZombieInfoAttribute.ZombieName: "ZombieFootball",
		ZombieInfoAttribute.CoolTime: 0.0,
		ZombieInfoAttribute.SunCost: 175,
		ZombieInfoAttribute.ZombieScenes: preload("res://scenes/character/zombie/zombie_008_football.tscn"),
		ZombieInfoAttribute.ZombieRowType:CharacterRegistry.ZombieRowType.Land
	},
	ZombieType.Z009Jackson:{
		ZombieInfoAttribute.ZombieName: "ZombieJackson",
		ZombieInfoAttribute.CoolTime: 0.0,
		ZombieInfoAttribute.SunCost: 300,
		ZombieInfoAttribute.ZombieScenes:preload("res://scenes/character/zombie/zombie_009_jackson.tscn"),
		ZombieInfoAttribute.ZombieRowType:CharacterRegistry.ZombieRowType.Land
	},
	ZombieType.Z010Dancer:{
		ZombieInfoAttribute.ZombieName: "ZombieDancer",
		ZombieInfoAttribute.CoolTime: 0.0,
		ZombieInfoAttribute.SunCost: 50,
		ZombieInfoAttribute.ZombieScenes:preload("res://scenes/character/zombie/zombie_010_dancer.tscn"),
		ZombieInfoAttribute.ZombieRowType:CharacterRegistry.ZombieRowType.Land
	},
	ZombieType.Z011Duckytube:{
		ZombieInfoAttribute.ZombieName: "ZombieDuckytube",
		ZombieInfoAttribute.CoolTime: 0.0,
		ZombieInfoAttribute.SunCost: 50,
		ZombieInfoAttribute.ZombieScenes:preload("res://scenes/character/zombie/zombie_011_duckytube.tscn"),
		ZombieInfoAttribute.ZombieRowType:CharacterRegistry.ZombieRowType.Both
	},
	ZombieType.Z012Snorkle:{
		ZombieInfoAttribute.ZombieName: "ZombieSnorkle",
		ZombieInfoAttribute.CoolTime: 0.0,
		ZombieInfoAttribute.SunCost: 75,
		ZombieInfoAttribute.ZombieScenes:preload("res://scenes/character/zombie/zombie_012_snorkle.tscn"),
		ZombieInfoAttribute.ZombieRowType:CharacterRegistry.ZombieRowType.Pool
	},
	ZombieType.Z013Zamboni:{
		ZombieInfoAttribute.ZombieName: "ZombieZamboni",
		ZombieInfoAttribute.CoolTime: 0.0,
		ZombieInfoAttribute.SunCost: 250,
		ZombieInfoAttribute.ZombieScenes:preload("res://scenes/character/zombie/zombie_013_zamboni.tscn"),
		ZombieInfoAttribute.ZombieRowType:CharacterRegistry.ZombieRowType.Land
	},
	ZombieType.Z014Bobsled:{
		ZombieInfoAttribute.ZombieName: "ZombieBobsled",
		ZombieInfoAttribute.CoolTime: 0.0,
		ZombieInfoAttribute.SunCost: 200,
		ZombieInfoAttribute.ZombieScenes:preload("res://scenes/character/zombie/zombie_014_bobsled.tscn"),
		ZombieInfoAttribute.ZombieRowType:CharacterRegistry.ZombieRowType.Land
	},
	ZombieType.Z015Dolphinrider:{
		ZombieInfoAttribute.ZombieName: "ZombieDolphinrider",
		ZombieInfoAttribute.CoolTime: 0.0,
		ZombieInfoAttribute.SunCost: 150,
		ZombieInfoAttribute.ZombieScenes:preload("res://scenes/character/zombie/zombie_015_dolphinrider.tscn"),
		ZombieInfoAttribute.ZombieRowType:CharacterRegistry.ZombieRowType.Pool
	},
	ZombieType.Z016Jackbox:{
		ZombieInfoAttribute.ZombieName: "ZombieJackbox",
		ZombieInfoAttribute.CoolTime: 0.0,
		ZombieInfoAttribute.SunCost: 75,
		ZombieInfoAttribute.ZombieScenes:preload("res://scenes/character/zombie/zombie_016_jackbox.tscn"),
		ZombieInfoAttribute.ZombieRowType:CharacterRegistry.ZombieRowType.Land
	},
	ZombieType.Z017Balloon:{
		ZombieInfoAttribute.ZombieName: "ZombieBallon",
		ZombieInfoAttribute.CoolTime: 0.0,
		ZombieInfoAttribute.SunCost: 75,
		ZombieInfoAttribute.ZombieScenes:preload("res://scenes/character/zombie/zombie_017_balloon.tscn"),
		ZombieInfoAttribute.ZombieRowType:CharacterRegistry.ZombieRowType.Both
	},
	ZombieType.Z018Digger:{
		ZombieInfoAttribute.ZombieName: "ZombieDigger",
		ZombieInfoAttribute.CoolTime: 0.0,
		ZombieInfoAttribute.SunCost: 125,
		ZombieInfoAttribute.ZombieScenes:preload("res://scenes/character/zombie/zombie_018_digger.tscn"),
		ZombieInfoAttribute.ZombieRowType:CharacterRegistry.ZombieRowType.Land
	},
	ZombieType.Z019Pogo:{
		ZombieInfoAttribute.ZombieName: "ZombiePogo",
		ZombieInfoAttribute.CoolTime: 0.0,
		ZombieInfoAttribute.SunCost: 125,
		ZombieInfoAttribute.ZombieScenes:preload("res://scenes/character/zombie/zombie_019_pogo.tscn"),
		ZombieInfoAttribute.ZombieRowType:CharacterRegistry.ZombieRowType.Land
	},
	ZombieType.Z020Yeti:{
		ZombieInfoAttribute.ZombieName: "ZombieYeti",
		ZombieInfoAttribute.CoolTime: 0.0,
		ZombieInfoAttribute.SunCost: 100,
		ZombieInfoAttribute.ZombieScenes:preload("res://scenes/character/zombie/zombie_020_yeti.tscn"),
		ZombieInfoAttribute.ZombieRowType:CharacterRegistry.ZombieRowType.Land
	},
	ZombieType.Z021Bungi:{
		ZombieInfoAttribute.ZombieName: "ZombieBungi",
		ZombieInfoAttribute.CoolTime: 0.0,
		ZombieInfoAttribute.SunCost: 125,
		ZombieInfoAttribute.ZombieScenes:preload("res://scenes/character/zombie/zombie_021_bungi.tscn"),
		ZombieInfoAttribute.ZombieRowType:CharacterRegistry.ZombieRowType.Both
	},
	ZombieType.Z022Ladder:{
		ZombieInfoAttribute.ZombieName: "ZombieLadder",
		ZombieInfoAttribute.CoolTime: 0.0,
		ZombieInfoAttribute.SunCost: 150,
		ZombieInfoAttribute.ZombieScenes:preload("res://scenes/character/zombie/zombie_022_ladder.tscn"),
		ZombieInfoAttribute.ZombieRowType:CharacterRegistry.ZombieRowType.Land
	},
	ZombieType.Z023Catapult:{
		ZombieInfoAttribute.ZombieName: "ZombieCatapult",
		ZombieInfoAttribute.CoolTime: 0.0,
		ZombieInfoAttribute.SunCost: 200,
		ZombieInfoAttribute.ZombieScenes:preload("res://scenes/character/zombie/zombie_023_catapult.tscn"),
		ZombieInfoAttribute.ZombieRowType:CharacterRegistry.ZombieRowType.Land
	},
	ZombieType.Z024Gargantuar:{
		ZombieInfoAttribute.ZombieName: "ZombieGargantuar",
		ZombieInfoAttribute.CoolTime: 0.0,
		ZombieInfoAttribute.SunCost: 300,
		ZombieInfoAttribute.ZombieScenes:preload("res://scenes/character/zombie/zombie_024_gargantuar.tscn"),
		ZombieInfoAttribute.ZombieRowType:CharacterRegistry.ZombieRowType.Land
	},
	ZombieType.Z025Imp:{
		ZombieInfoAttribute.ZombieName: "ZombieImp",
		ZombieInfoAttribute.CoolTime: 0.0,
		ZombieInfoAttribute.SunCost: 50,
		ZombieInfoAttribute.ZombieScenes:preload("res://scenes/character/zombie/zombie_025_imp.tscn"),
		ZombieInfoAttribute.ZombieRowType:CharacterRegistry.ZombieRowType.Land
	},

	## 单独雪橇僵尸
	ZombieType.Z1001BobsledSingle:{
		ZombieInfoAttribute.ZombieName: "ZombieBobsledSingle",
		ZombieInfoAttribute.CoolTime: 0.0,
		ZombieInfoAttribute.SunCost: 50,
		ZombieInfoAttribute.ZombieScenes:preload("res://scenes/character/zombie/zombie_1001_bobsled_signle.tscn"),
		ZombieInfoAttribute.ZombieRowType:CharacterRegistry.ZombieRowType.Land
	},
}

## 每种僵尸消耗的出怪战力，供自然波次和僵王放置技能只读访问，无需复制。[br]
## 未列出的类型不能参与按战力预算生成；战力不包含生成后衍生出的其他僵尸。
const ZombieSpawnPower: Dictionary[ZombieType, int] = {
	ZombieType.Z001Norm: 1,		# 普僵战力
	ZombieType.Z002Flag: 1,		# 旗帜战力
	ZombieType.Z003Cone: 2,		# 路障战力
	ZombieType.Z004PoleVaulter: 2,	# 撑杆战力
	ZombieType.Z005Bucket: 4,		# 铁桶战力

	ZombieType.Z006Paper: 2,		# 读报战力
	ZombieType.Z007ScreenDoor: 4,	# 铁门战力
	ZombieType.Z008Football: 7,	# 橄榄球战力
	ZombieType.Z009Jackson: 5,		# 舞王战力
	ZombieType.Z010Dancer: 1,		# 伴舞战力

	ZombieType.Z012Snorkle: 3,		# 潜水
	ZombieType.Z013Zamboni: 7,		# 冰车
	ZombieType.Z014Bobsled: 3,		# 滑雪四兄弟
	ZombieType.Z015Dolphinrider: 3,# 海豚僵尸

	ZombieType.Z016Jackbox: 3,		# 小丑
	ZombieType.Z017Balloon: 2,		# 气球
	ZombieType.Z018Digger: 4,		# 矿工
	ZombieType.Z019Pogo: 4,			# 跳跳
	ZombieType.Z020Yeti: 4,			# 雪人

	ZombieType.Z022Ladder: 4,		# 扶梯
	ZombieType.Z023Catapult: 5,		# 投篮
	ZombieType.Z024Gargantuar: 10,	# 伽刚特尔
	ZombieType.Z025Imp: 1,			# 小鬼
}

## 僵尸初始出怪权重；各出怪系统复制后独立调整，不修改公共基础数据。[br]
## 未列出的类型不参与此权重池，旗帜与小鬼等特殊生成仍由各自逻辑处理。
const ZombieSpawnWeights: Dictionary[ZombieType, int] = {
	ZombieType.Z001Norm: 4000,			# 普僵权重
	ZombieType.Z003Cone: 4000,			# 路障权重
	ZombieType.Z004PoleVaulter: 2000,	# 撑杆权重
	ZombieType.Z005Bucket: 3000,		# 铁桶权重

	ZombieType.Z006Paper: 1000,		# 读报权重
	ZombieType.Z007ScreenDoor: 3500,	# 铁门权重
	ZombieType.Z008Football: 2000,		# 橄榄球权重
	ZombieType.Z009Jackson: 1000,		# 舞王权重
	ZombieType.Z010Dancer: 4000,		# 伴舞权重

	ZombieType.Z012Snorkle: 2000,		# 潜水
	ZombieType.Z013Zamboni: 2000,		# 冰车
	ZombieType.Z014Bobsled: 2000,		# 滑雪四兄弟
	ZombieType.Z015Dolphinrider: 1500,	# 海豚僵尸

	ZombieType.Z016Jackbox: 1000,		# 小丑
	ZombieType.Z017Balloon: 2000,		# 气球
	ZombieType.Z018Digger: 1000,		# 矿工
	ZombieType.Z019Pogo: 1000,			# 跳跳
	ZombieType.Z020Yeti: 1,			# 雪人

	ZombieType.Z022Ladder: 1000,		# 扶梯
	ZombieType.Z023Catapult: 1500,	# 投篮
	ZombieType.Z024Gargantuar: 1500,	# 伽刚特尔
}


## 获取僵尸属性方法
func get_zombie_info(zombie_type:ZombieType, info_attribute:ZombieInfoAttribute):
	if zombie_type == 0:
		print("warning: 获取空僵尸信息")
		return null
	var curr_zombie_info = ZombieInfo[zombie_type]
	return curr_zombie_info[info_attribute]
#endregion

#region 僵王信息

#region 僵王
## 僵王使用独立类型，不参与普通僵尸的自然刷新列表；新增类型保持已有编号不变。
enum ZombieBossType {
	Null = 0,
	ZB001Doctor = 1,
}

## 注册表只保存公共定义，血量和死亡状态由每局生成的僵王实例维护。
enum ZombieBossInfoAttribute {
	BossName,
	BossScenes,
}
#endregion

## 通过 Global.character_registry 查询场景，关卡只需保存 ZombieBossType。
const ZombieBossInfo = {
	ZombieBossType.ZB001Doctor: {
		ZombieBossInfoAttribute.BossName: "ZB001Doctor",
		ZombieBossInfoAttribute.BossScenes: preload("res://scenes/character/zombie_boss/zombie_boss_001_doctor.tscn"),
	},
}


## 空类型或未注册类型返回 null，由生成入口决定如何处理，不回退成其他角色。
func get_zombie_boss_info(boss_type: ZombieBossType, info_attribute: ZombieBossInfoAttribute):
	if boss_type == ZombieBossType.Null:
		print("warning: 获取空僵王信息")
		return null
	if not ZombieBossInfo.has(boss_type):
		push_error("CharacterRegistry：未注册的僵王类型：%s" % boss_type)
		return null
	var curr_boss_info: Dictionary = ZombieBossInfo[boss_type]
	return curr_boss_info.get(info_attribute)
#endregion
