extends Node
class_name CharacterRegistry

## 紫卡植物种植前置植物
@export var AllPrePlantPurple:Dictionary[EnumsCharacter.PlantType, EnumsCharacter.PlantType]= {
	EnumsCharacter.PlantType.P041GatlingPea:EnumsCharacter.PlantType.P008PeaShooterDouble,
	EnumsCharacter.PlantType.P042TwinSunFlower:EnumsCharacter.PlantType.P002SunFlower,
	EnumsCharacter.PlantType.P043GloomShroom:EnumsCharacter.PlantType.P011FumeShroom,
	EnumsCharacter.PlantType.P044Cattail:EnumsCharacter.PlantType.P017LilyPad,
	EnumsCharacter.PlantType.P045WinterMelon:EnumsCharacter.PlantType.P040MelonPult,
	EnumsCharacter.PlantType.P046GoldMagnet:EnumsCharacter.PlantType.P032MagnetShroom,
	EnumsCharacter.PlantType.P047SpikeRock:EnumsCharacter.PlantType.P022Caltrop,
	EnumsCharacter.PlantType.P048CobCannon:EnumsCharacter.PlantType.P035CornPult,
}

const PlantInfo = {
	EnumsCharacter.PlantType.P001PeaShooterSingle: {
		EnumsCharacter.PlantInfoAttribute.PlantName: "PeaShooterSingle",
		EnumsCharacter.PlantInfoAttribute.CoolTime: 7.5,
		EnumsCharacter.PlantInfoAttribute.SunCost: 100,
		EnumsCharacter.PlantInfoAttribute.PlantConditionResource:preload("res://resources/character_resource/plant_condition/000_common_plant_land.tres"),
		EnumsCharacter.PlantInfoAttribute.PlantScenes : preload("res://scenes/character/plant/plant_001_pea_shooter_single.tscn")
		},
	EnumsCharacter.PlantType.P002SunFlower: {
		EnumsCharacter.PlantInfoAttribute.PlantName: "SunFlower",
		EnumsCharacter.PlantInfoAttribute.CoolTime: 7.5,
		EnumsCharacter.PlantInfoAttribute.SunCost: 50,
		EnumsCharacter.PlantInfoAttribute.PlantConditionResource:preload("res://resources/character_resource/plant_condition/000_common_plant_land.tres"),
		EnumsCharacter.PlantInfoAttribute.PlantScenes : preload("res://scenes/character/plant/plant_002_sun_flower.tscn")
		},
	EnumsCharacter.PlantType.P003CherryBomb: {
		EnumsCharacter.PlantInfoAttribute.PlantName: "CherryBomb",
		EnumsCharacter.PlantInfoAttribute.CoolTime: 50.0,
		EnumsCharacter.PlantInfoAttribute.SunCost: 150,
		EnumsCharacter.PlantInfoAttribute.PlantConditionResource : preload("res://resources/character_resource/plant_condition/000_common_plant_land.tres"),
		EnumsCharacter.PlantInfoAttribute.PlantScenes : preload("res://scenes/character/plant/plant_003_cherry_bomb.tscn")
		},
	EnumsCharacter.PlantType.P004WallNut: {
		EnumsCharacter.PlantInfoAttribute.PlantName: "WallNut",
		EnumsCharacter.PlantInfoAttribute.CoolTime: 30.0,
		EnumsCharacter.PlantInfoAttribute.SunCost: 50,
		EnumsCharacter.PlantInfoAttribute.PlantConditionResource : preload("res://resources/character_resource/plant_condition/000_common_plant_land.tres"),
		EnumsCharacter.PlantInfoAttribute.PlantScenes : preload("res://scenes/character/plant/plant_004_wall_nut.tscn")
		},
	EnumsCharacter.PlantType.P005PotatoMine: {
		EnumsCharacter.PlantInfoAttribute.PlantName: "PotatoMine",
		EnumsCharacter.PlantInfoAttribute.CoolTime: 30.0,
		EnumsCharacter.PlantInfoAttribute.SunCost: 25,
		EnumsCharacter.PlantInfoAttribute.PlantConditionResource : preload("res://resources/character_resource/plant_condition/005_potato_mine.tres"),
		EnumsCharacter.PlantInfoAttribute.PlantScenes : preload("res://scenes/character/plant/plant_005_potato_mine.tscn")
		},
	EnumsCharacter.PlantType.P006SnowPea: {
		EnumsCharacter.PlantInfoAttribute.PlantName: "SnowPea",
		EnumsCharacter.PlantInfoAttribute.CoolTime: 7.5,
		EnumsCharacter.PlantInfoAttribute.SunCost: 175,
		EnumsCharacter.PlantInfoAttribute.PlantConditionResource : preload("res://resources/character_resource/plant_condition/000_common_plant_land.tres"),
		EnumsCharacter.PlantInfoAttribute.PlantScenes : preload("res://scenes/character/plant/plant_006_snow_pea.tscn")
		},
	EnumsCharacter.PlantType.P007Chomper: {
		EnumsCharacter.PlantInfoAttribute.PlantName: "Chomper",
		EnumsCharacter.PlantInfoAttribute.CoolTime: 7.5,
		EnumsCharacter.PlantInfoAttribute.SunCost: 150,
		EnumsCharacter.PlantInfoAttribute.PlantConditionResource : preload("res://resources/character_resource/plant_condition/000_common_plant_land.tres"),
		EnumsCharacter.PlantInfoAttribute.PlantScenes : preload("res://scenes/character/plant/plant_007_chomper.tscn")
		},
	EnumsCharacter.PlantType.P008PeaShooterDouble: {
		EnumsCharacter.PlantInfoAttribute.PlantName: "PeaShooterDouble",
		EnumsCharacter.PlantInfoAttribute.CoolTime: 7.5,
		EnumsCharacter.PlantInfoAttribute.SunCost: 200,
		EnumsCharacter.PlantInfoAttribute.PlantConditionResource : preload("res://resources/character_resource/plant_condition/000_common_plant_land.tres"),
		EnumsCharacter.PlantInfoAttribute.PlantScenes : preload("res://scenes/character/plant/plant_008_pea_shooter_double.tscn")
		},
		#
	EnumsCharacter.PlantType.P009PuffShroom: {
		EnumsCharacter.PlantInfoAttribute.PlantName: "PuffShroom",
		EnumsCharacter.PlantInfoAttribute.CoolTime: 7.5,
		EnumsCharacter.PlantInfoAttribute.SunCost: 0,
		EnumsCharacter.PlantInfoAttribute.PlantConditionResource : preload("res://resources/character_resource/plant_condition/000_common_plant_land.tres"),
		EnumsCharacter.PlantInfoAttribute.PlantScenes : preload("res://scenes/character/plant/plant_009_puff.tscn")
		},
	EnumsCharacter.PlantType.P010SunShroom: {
		EnumsCharacter.PlantInfoAttribute.PlantName: "SunShroom",
		EnumsCharacter.PlantInfoAttribute.CoolTime: 7.5,
		EnumsCharacter.PlantInfoAttribute.SunCost: 25,
		EnumsCharacter.PlantInfoAttribute.PlantConditionResource : preload("res://resources/character_resource/plant_condition/000_common_plant_land.tres"),
		EnumsCharacter.PlantInfoAttribute.PlantScenes : preload("res://scenes/character/plant/plant_010_sun_shroom.tscn")
		},
	EnumsCharacter.PlantType.P011FumeShroom: {
		EnumsCharacter.PlantInfoAttribute.PlantName: "FumeShroom",
		EnumsCharacter.PlantInfoAttribute.CoolTime: 7.5,
		EnumsCharacter.PlantInfoAttribute.SunCost: 75,
		EnumsCharacter.PlantInfoAttribute.PlantConditionResource : preload("res://resources/character_resource/plant_condition/000_common_plant_land.tres"),
		EnumsCharacter.PlantInfoAttribute.PlantScenes : preload("res://scenes/character/plant/plant_011_fume_shroom.tscn")
		},
	EnumsCharacter.PlantType.P012GraveBuster: {
		EnumsCharacter.PlantInfoAttribute.PlantName: "GraveBuster",
		EnumsCharacter.PlantInfoAttribute.CoolTime: 7.5,
		EnumsCharacter.PlantInfoAttribute.SunCost: 75,
		EnumsCharacter.PlantInfoAttribute.PlantConditionResource : preload("res://resources/character_resource/plant_condition/012_grave_buster.tres"),
		EnumsCharacter.PlantInfoAttribute.PlantScenes : preload("res://scenes/character/plant/plant_012_grave_buster.tscn")
		},
	EnumsCharacter.PlantType.P013HypnoShroom: {
		EnumsCharacter.PlantInfoAttribute.PlantName: "HypnoShroom",
		EnumsCharacter.PlantInfoAttribute.CoolTime: 30.0,
		EnumsCharacter.PlantInfoAttribute.SunCost: 75,
		EnumsCharacter.PlantInfoAttribute.PlantConditionResource : preload("res://resources/character_resource/plant_condition/000_common_plant_land.tres"),
		EnumsCharacter.PlantInfoAttribute.PlantScenes : preload("res://scenes/character/plant/plant_013_hypno_shroom.tscn")
		},
	EnumsCharacter.PlantType.P014ScaredyShroom: {
		EnumsCharacter.PlantInfoAttribute.PlantName: "ScaredyShroom",
		EnumsCharacter.PlantInfoAttribute.CoolTime: 7.5,
		EnumsCharacter.PlantInfoAttribute.SunCost: 25,
		EnumsCharacter.PlantInfoAttribute.PlantConditionResource : preload("res://resources/character_resource/plant_condition/000_common_plant_land.tres"),
		EnumsCharacter.PlantInfoAttribute.PlantScenes : preload("res://scenes/character/plant/plant_014_scaredy_shroom.tscn")
		},
	EnumsCharacter.PlantType.P015IceShroom: {
		EnumsCharacter.PlantInfoAttribute.PlantName: "IceShroom",
		EnumsCharacter.PlantInfoAttribute.CoolTime: 50.0,
		EnumsCharacter.PlantInfoAttribute.SunCost: 75,
		EnumsCharacter.PlantInfoAttribute.PlantConditionResource : preload("res://resources/character_resource/plant_condition/000_common_plant_land.tres"),
		EnumsCharacter.PlantInfoAttribute.PlantScenes : preload("res://scenes/character/plant/plant_015_ice_shroom.tscn")
		},
	EnumsCharacter.PlantType.P016DoomShroom: {
		EnumsCharacter.PlantInfoAttribute.PlantName: "DoomShroom",
		EnumsCharacter.PlantInfoAttribute.CoolTime: 50.0,
		EnumsCharacter.PlantInfoAttribute.SunCost: 125,
		EnumsCharacter.PlantInfoAttribute.PlantConditionResource : preload("res://resources/character_resource/plant_condition/000_common_plant_land.tres"),
		EnumsCharacter.PlantInfoAttribute.PlantScenes : preload("res://scenes/character/plant/plant_016_doom_shroom.tscn")
		},
	EnumsCharacter.PlantType.P017LilyPad: {
		EnumsCharacter.PlantInfoAttribute.PlantName: "LilyPad",
		EnumsCharacter.PlantInfoAttribute.CoolTime: 7.5,
		EnumsCharacter.PlantInfoAttribute.SunCost: 25,
		EnumsCharacter.PlantInfoAttribute.PlantConditionResource : preload("res://resources/character_resource/plant_condition/017_lily_pad.tres"),
		EnumsCharacter.PlantInfoAttribute.PlantScenes : preload("res://scenes/character/plant/plant_017_lily_pad.tscn")
		},
	EnumsCharacter.PlantType.P018Squash: {
		EnumsCharacter.PlantInfoAttribute.PlantName: "Squash",
		EnumsCharacter.PlantInfoAttribute.CoolTime: 30.0,
		EnumsCharacter.PlantInfoAttribute.SunCost: 50,
		EnumsCharacter.PlantInfoAttribute.PlantConditionResource : preload("res://resources/character_resource/plant_condition/000_common_plant_land.tres"),
		EnumsCharacter.PlantInfoAttribute.PlantScenes : preload("res://scenes/character/plant/plant_018_squash.tscn")
		},
	EnumsCharacter.PlantType.P019ThreePeater: {
		EnumsCharacter.PlantInfoAttribute.PlantName: "ThreePeater",
		EnumsCharacter.PlantInfoAttribute.CoolTime: 7.5,
		EnumsCharacter.PlantInfoAttribute.SunCost: 325,
		EnumsCharacter.PlantInfoAttribute.PlantConditionResource : preload("res://resources/character_resource/plant_condition/000_common_plant_land.tres"),
		EnumsCharacter.PlantInfoAttribute.PlantScenes : preload("res://scenes/character/plant/plant_019_three_peater.tscn")
		},
	EnumsCharacter.PlantType.P020TangleKelp: {
		EnumsCharacter.PlantInfoAttribute.PlantName: "TangleKelp",
		EnumsCharacter.PlantInfoAttribute.CoolTime: 30.0,
		EnumsCharacter.PlantInfoAttribute.SunCost: 25,
		EnumsCharacter.PlantInfoAttribute.PlantConditionResource : preload("res://resources/character_resource/plant_condition/020_tanglekelp.tres"),
		EnumsCharacter.PlantInfoAttribute.PlantScenes : preload("res://scenes/character/plant/plant_020_tanglekelp.tscn")
		},
	EnumsCharacter.PlantType.P021Jalapeno: {
		EnumsCharacter.PlantInfoAttribute.PlantName: "Jalapeno",
		EnumsCharacter.PlantInfoAttribute.CoolTime: 50.0,
		EnumsCharacter.PlantInfoAttribute.SunCost: 125,
		EnumsCharacter.PlantInfoAttribute.PlantConditionResource : preload("res://resources/character_resource/plant_condition/000_common_plant_land.tres"),
		EnumsCharacter.PlantInfoAttribute.PlantScenes : preload("res://scenes/character/plant/plant_021_jalapeno.tscn")
		},
	EnumsCharacter.PlantType.P022Caltrop: {
		EnumsCharacter.PlantInfoAttribute.PlantName: "Caltrop",
		EnumsCharacter.PlantInfoAttribute.CoolTime: 7.5,
		EnumsCharacter.PlantInfoAttribute.SunCost: 125,
		EnumsCharacter.PlantInfoAttribute.PlantConditionResource : preload("res://resources/character_resource/plant_condition/022_caltrop.tres"),
		EnumsCharacter.PlantInfoAttribute.PlantScenes : preload("res://scenes/character/plant/plant_022_caltrop.tscn")
		},
	EnumsCharacter.PlantType.P023TorchWood: {
		EnumsCharacter.PlantInfoAttribute.PlantName: "TorchWood",
		EnumsCharacter.PlantInfoAttribute.CoolTime: 7.5,
		EnumsCharacter.PlantInfoAttribute.SunCost: 175,
		EnumsCharacter.PlantInfoAttribute.PlantConditionResource : preload("res://resources/character_resource/plant_condition/000_common_plant_land.tres"),
		EnumsCharacter.PlantInfoAttribute.PlantScenes : preload("res://scenes/character/plant/plant_023_torch_wood.tscn")
		},
	EnumsCharacter.PlantType.P024TallNut: {
		EnumsCharacter.PlantInfoAttribute.PlantName: "TallNut",
		EnumsCharacter.PlantInfoAttribute.CoolTime: 30.0,
		EnumsCharacter.PlantInfoAttribute.SunCost: 175,
		EnumsCharacter.PlantInfoAttribute.PlantConditionResource : preload("res://resources/character_resource/plant_condition/000_common_plant_land.tres"),
		EnumsCharacter.PlantInfoAttribute.PlantScenes : preload("res://scenes/character/plant/plant_024_tall_nut.tscn")
		},

	EnumsCharacter.PlantType.P025SeaShroom: {
		EnumsCharacter.PlantInfoAttribute.PlantName: "SeaShroom",
		EnumsCharacter.PlantInfoAttribute.CoolTime: 30.0,
		EnumsCharacter.PlantInfoAttribute.SunCost: 0,
		EnumsCharacter.PlantInfoAttribute.PlantConditionResource : preload("res://resources/character_resource/plant_condition/020_tanglekelp.tres"),
		EnumsCharacter.PlantInfoAttribute.PlantScenes : preload("res://scenes/character/plant/plant_025_sea_shroom.tscn")
		},
	EnumsCharacter.PlantType.P026Plantern: {
		EnumsCharacter.PlantInfoAttribute.PlantName: "Plantern",
		EnumsCharacter.PlantInfoAttribute.CoolTime: 30.0,
		EnumsCharacter.PlantInfoAttribute.SunCost: 25,
		EnumsCharacter.PlantInfoAttribute.PlantConditionResource : preload("res://resources/character_resource/plant_condition/000_common_plant_land.tres"),
		EnumsCharacter.PlantInfoAttribute.PlantScenes : preload("res://scenes/character/plant/plant_026_plantern.tscn")
		},
	EnumsCharacter.PlantType.P027Cactus: {
		EnumsCharacter.PlantInfoAttribute.PlantName: "Cactus",
		EnumsCharacter.PlantInfoAttribute.CoolTime: 7.5,
		EnumsCharacter.PlantInfoAttribute.SunCost: 125,
		EnumsCharacter.PlantInfoAttribute.PlantConditionResource :  preload("res://resources/character_resource/plant_condition/000_common_plant_land.tres"),
		EnumsCharacter.PlantInfoAttribute.PlantScenes : preload("res://scenes/character/plant/plant_027_cactus.tscn")
		},
	EnumsCharacter.PlantType.P028Blover: {
		EnumsCharacter.PlantInfoAttribute.PlantName: "Blover",
		EnumsCharacter.PlantInfoAttribute.CoolTime: 7.5,
		EnumsCharacter.PlantInfoAttribute.SunCost: 100,
		EnumsCharacter.PlantInfoAttribute.PlantConditionResource :  preload("res://resources/character_resource/plant_condition/000_common_plant_land.tres"),
		EnumsCharacter.PlantInfoAttribute.PlantScenes : preload("res://scenes/character/plant/plant_028_blover.tscn")
		},
	EnumsCharacter.PlantType.P029SplitPea: {
		EnumsCharacter.PlantInfoAttribute.PlantName: "SplitPea",
		EnumsCharacter.PlantInfoAttribute.CoolTime: 7.5,
		EnumsCharacter.PlantInfoAttribute.SunCost: 125,
		EnumsCharacter.PlantInfoAttribute.PlantConditionResource :  preload("res://resources/character_resource/plant_condition/000_common_plant_land.tres"),
		EnumsCharacter.PlantInfoAttribute.PlantScenes : preload("res://scenes/character/plant/plant_029_split_pea.tscn")
		},
	EnumsCharacter.PlantType.P030StarFruit: {
		EnumsCharacter.PlantInfoAttribute.PlantName: "StarFruit",
		EnumsCharacter.PlantInfoAttribute.CoolTime: 7.5,
		EnumsCharacter.PlantInfoAttribute.SunCost: 125,
		EnumsCharacter.PlantInfoAttribute.PlantConditionResource :  preload("res://resources/character_resource/plant_condition/000_common_plant_land.tres"),
		EnumsCharacter.PlantInfoAttribute.PlantScenes : preload("res://scenes/character/plant/plant_030_star_fruit.tscn")
		},
	EnumsCharacter.PlantType.P031Pumpkin: {
		EnumsCharacter.PlantInfoAttribute.PlantName: "Pumpkin",
		EnumsCharacter.PlantInfoAttribute.CoolTime: 30.0,
		EnumsCharacter.PlantInfoAttribute.SunCost: 125,
		EnumsCharacter.PlantInfoAttribute.PlantConditionResource :  preload("res://resources/character_resource/plant_condition/031_Pumpkin.tres"),
		EnumsCharacter.PlantInfoAttribute.PlantScenes : preload("res://scenes/character/plant/plant_031_pumpkin.tscn")
		},
	EnumsCharacter.PlantType.P032MagnetShroom: {
		EnumsCharacter.PlantInfoAttribute.PlantName: "MagnetShroom",
		EnumsCharacter.PlantInfoAttribute.CoolTime: 7.5,
		EnumsCharacter.PlantInfoAttribute.SunCost: 100,
		EnumsCharacter.PlantInfoAttribute.PlantConditionResource :  preload("res://resources/character_resource/plant_condition/000_common_plant_land.tres"),
		EnumsCharacter.PlantInfoAttribute.PlantScenes : preload("res://scenes/character/plant/plant_032_magnet_shroom.tscn")
		},

	EnumsCharacter.PlantType.P033CabbagePult: {
		EnumsCharacter.PlantInfoAttribute.PlantName: "CabbagePult",
		EnumsCharacter.PlantInfoAttribute.CoolTime: 7.5,
		EnumsCharacter.PlantInfoAttribute.SunCost: 100,
		EnumsCharacter.PlantInfoAttribute.PlantConditionResource :  preload("res://resources/character_resource/plant_condition/000_common_plant_land.tres"),
		EnumsCharacter.PlantInfoAttribute.PlantScenes : preload("res://scenes/character/plant/plant_033_cabbage_pult.tscn")
		},
	EnumsCharacter.PlantType.P034FlowerPot: {
		EnumsCharacter.PlantInfoAttribute.PlantName: "FlowerPot",
		EnumsCharacter.PlantInfoAttribute.CoolTime: 7.5,
		EnumsCharacter.PlantInfoAttribute.SunCost: 25,
		EnumsCharacter.PlantInfoAttribute.PlantConditionResource :  preload("res://resources/character_resource/plant_condition/034_flower_pot.tres"),
		EnumsCharacter.PlantInfoAttribute.PlantScenes : preload("res://scenes/character/plant/plant_034_flower_pot.tscn")
		},
	EnumsCharacter.PlantType.P035CornPult: {
		EnumsCharacter.PlantInfoAttribute.PlantName: "CornPult",
		EnumsCharacter.PlantInfoAttribute.CoolTime: 7.5,
		EnumsCharacter.PlantInfoAttribute.SunCost: 125,
		EnumsCharacter.PlantInfoAttribute.PlantConditionResource :  preload("res://resources/character_resource/plant_condition/000_common_plant_land.tres"),
		EnumsCharacter.PlantInfoAttribute.PlantScenes : preload("res://scenes/character/plant/plant_035_corn_pult.tscn")
		},
	EnumsCharacter.PlantType.P036CoffeeBean: {
		EnumsCharacter.PlantInfoAttribute.PlantName: "CoffeeBean",
		EnumsCharacter.PlantInfoAttribute.CoolTime: 7.5,
		EnumsCharacter.PlantInfoAttribute.SunCost: 75,
		EnumsCharacter.PlantInfoAttribute.PlantConditionResource :  preload("res://resources/character_resource/plant_condition/036_coffee_bean.tres"),
		EnumsCharacter.PlantInfoAttribute.PlantScenes : preload("res://scenes/character/plant/plant_036_coffee_bean.tscn")
		},
	EnumsCharacter.PlantType.P037Garlic: {
		EnumsCharacter.PlantInfoAttribute.PlantName: "Garlic",
		EnumsCharacter.PlantInfoAttribute.CoolTime: 7.5,
		EnumsCharacter.PlantInfoAttribute.SunCost: 50,
		EnumsCharacter.PlantInfoAttribute.PlantConditionResource :  preload("res://resources/character_resource/plant_condition/000_common_plant_land.tres"),
		EnumsCharacter.PlantInfoAttribute.PlantScenes : preload("res://scenes/character/plant/plant_037_garlic.tscn")
		},
	EnumsCharacter.PlantType.P038UmbrellaLeaf: {
		EnumsCharacter.PlantInfoAttribute.PlantName: "UmbrellaLeaf",
		EnumsCharacter.PlantInfoAttribute.CoolTime: 7.5,
		EnumsCharacter.PlantInfoAttribute.SunCost: 100,
		EnumsCharacter.PlantInfoAttribute.PlantConditionResource :  preload("res://resources/character_resource/plant_condition/000_common_plant_land.tres"),
		EnumsCharacter.PlantInfoAttribute.PlantScenes : preload("res://scenes/character/plant/plant_038_umbrella_leaf.tscn")
		},
	EnumsCharacter.PlantType.P039MariGold: {
		EnumsCharacter.PlantInfoAttribute.PlantName: "MariGold",
		EnumsCharacter.PlantInfoAttribute.CoolTime: 30.0,
		EnumsCharacter.PlantInfoAttribute.SunCost: 50,
		EnumsCharacter.PlantInfoAttribute.PlantConditionResource :  preload("res://resources/character_resource/plant_condition/000_common_plant_land.tres"),
		EnumsCharacter.PlantInfoAttribute.PlantScenes : preload("res://scenes/character/plant/plant_039_mari_gold.tscn")
		},
	EnumsCharacter.PlantType.P040MelonPult: {
		EnumsCharacter.PlantInfoAttribute.PlantName: "MelonPult",
		EnumsCharacter.PlantInfoAttribute.CoolTime: 7.5,
		EnumsCharacter.PlantInfoAttribute.SunCost: 300,
		EnumsCharacter.PlantInfoAttribute.PlantConditionResource :  preload("res://resources/character_resource/plant_condition/000_common_plant_land.tres"),
		EnumsCharacter.PlantInfoAttribute.PlantScenes : preload("res://scenes/character/plant/plant_040_melon_pult.tscn")
		},

	EnumsCharacter.PlantType.P041GatlingPea: {
		EnumsCharacter.PlantInfoAttribute.PlantName: "GatlingPea",
		EnumsCharacter.PlantInfoAttribute.CoolTime: 50.0,
		EnumsCharacter.PlantInfoAttribute.SunCost: 250,
		EnumsCharacter.PlantInfoAttribute.PlantConditionResource : preload("res://resources/character_resource/plant_condition/000_common_purple.tres"),
		EnumsCharacter.PlantInfoAttribute.PlantScenes : preload("res://scenes/character/plant/plant_041_gatling_pea.tscn")
		},

	EnumsCharacter.PlantType.P042TwinSunFlower: {
		EnumsCharacter.PlantInfoAttribute.PlantName: "TwinSunFlower",
		EnumsCharacter.PlantInfoAttribute.CoolTime: 50.0,
		EnumsCharacter.PlantInfoAttribute.SunCost: 150,
		EnumsCharacter.PlantInfoAttribute.PlantConditionResource : preload("res://resources/character_resource/plant_condition/000_common_purple.tres"),
		EnumsCharacter.PlantInfoAttribute.PlantScenes : preload("res://scenes/character/plant/plant_042_twin_sun_flower.tscn")
		},

	EnumsCharacter.PlantType.P043GloomShroom: {
		EnumsCharacter.PlantInfoAttribute.PlantName: "GloomShroom",
		EnumsCharacter.PlantInfoAttribute.CoolTime: 50.0,
		EnumsCharacter.PlantInfoAttribute.SunCost: 150,
		EnumsCharacter.PlantInfoAttribute.PlantConditionResource : preload("res://resources/character_resource/plant_condition/000_common_purple.tres"),
		EnumsCharacter.PlantInfoAttribute.PlantScenes : preload("res://scenes/character/plant/plant_043_gloom_shroom.tscn")
		},

	EnumsCharacter.PlantType.P044Cattail: {
		EnumsCharacter.PlantInfoAttribute.PlantName: "Cattail",
		EnumsCharacter.PlantInfoAttribute.CoolTime: 50.0,
		EnumsCharacter.PlantInfoAttribute.SunCost: 225,
		EnumsCharacter.PlantInfoAttribute.PlantConditionResource : preload("res://resources/character_resource/plant_condition/000_common_purple.tres"),
		EnumsCharacter.PlantInfoAttribute.PlantScenes : preload("res://scenes/character/plant/plant_044_cattail.tscn")
		},

	EnumsCharacter.PlantType.P045WinterMelon: {
		EnumsCharacter.PlantInfoAttribute.PlantName: "WinterMelon",
		EnumsCharacter.PlantInfoAttribute.CoolTime: 50.0,
		EnumsCharacter.PlantInfoAttribute.SunCost: 200,
		EnumsCharacter.PlantInfoAttribute.PlantConditionResource : preload("res://resources/character_resource/plant_condition/000_common_purple.tres"),
		EnumsCharacter.PlantInfoAttribute.PlantScenes : preload("res://scenes/character/plant/plant_045_winter_melon.tscn")
		},

	EnumsCharacter.PlantType.P046GoldMagnet: {
		EnumsCharacter.PlantInfoAttribute.PlantName: "GoldMagnet",
		EnumsCharacter.PlantInfoAttribute.CoolTime: 50.0,
		EnumsCharacter.PlantInfoAttribute.SunCost: 50,
		EnumsCharacter.PlantInfoAttribute.PlantConditionResource : preload("res://resources/character_resource/plant_condition/000_common_purple.tres"),
		EnumsCharacter.PlantInfoAttribute.PlantScenes : preload("res://scenes/character/plant/plant_046_gold_magnet.tscn")
		},

	EnumsCharacter.PlantType.P047SpikeRock: {
		EnumsCharacter.PlantInfoAttribute.PlantName: "SpikeRock",
		EnumsCharacter.PlantInfoAttribute.CoolTime: 50.0,
		EnumsCharacter.PlantInfoAttribute.SunCost: 125,
		EnumsCharacter.PlantInfoAttribute.PlantConditionResource : preload("res://resources/character_resource/plant_condition/000_common_purple.tres"),
		EnumsCharacter.PlantInfoAttribute.PlantScenes : preload("res://scenes/character/plant/plant_047_spike_rock.tscn")
		},

	EnumsCharacter.PlantType.P048CobCannon: {
		EnumsCharacter.PlantInfoAttribute.PlantName: "CobCannon",
		EnumsCharacter.PlantInfoAttribute.CoolTime: 50.0,
		EnumsCharacter.PlantInfoAttribute.SunCost: 500,
		EnumsCharacter.PlantInfoAttribute.PlantConditionResource : preload("res://resources/character_resource/plant_condition/048_cob_cannon.tres"),
		EnumsCharacter.PlantInfoAttribute.PlantScenes : preload("res://scenes/character/plant/plant_048_cob_cannon.tscn")
		},

	EnumsCharacter.PlantType.P049PeaShooterDoubleReverse: {
		EnumsCharacter.PlantInfoAttribute.PlantName: "PeaShooterDoubleReverse",
		EnumsCharacter.PlantInfoAttribute.CoolTime: 7.5,
		EnumsCharacter.PlantInfoAttribute.SunCost: 200,
		EnumsCharacter.PlantInfoAttribute.PlantConditionResource : preload("res://resources/character_resource/plant_condition/000_common_plant_land.tres"),
		EnumsCharacter.PlantInfoAttribute.PlantScenes : preload("res://scenes/character/plant/plant_049_pea_shooter_double_reverse.tscn")
		},

	## 模仿者
	EnumsCharacter.PlantType.P999Imitater:{
		EnumsCharacter.PlantInfoAttribute.PlantName: "Imitater",
		EnumsCharacter.PlantInfoAttribute.CoolTime: 50.0,
		EnumsCharacter.PlantInfoAttribute.SunCost: 0,
		EnumsCharacter.PlantInfoAttribute.PlantConditionResource :  preload("res://resources/character_resource/plant_condition/999_imitater.tres"),
		EnumsCharacter.PlantInfoAttribute.PlantScenes :  preload("res://scenes/character/plant/plant_999_imitater.tscn")
		},


	## 发芽
	EnumsCharacter.PlantType.P1000Sprout:{
		EnumsCharacter.PlantInfoAttribute.PlantName: "Sprout",
		EnumsCharacter.PlantInfoAttribute.CoolTime: 7.5,
		EnumsCharacter.PlantInfoAttribute.SunCost: 50,
		EnumsCharacter.PlantInfoAttribute.PlantConditionResource :  preload("res://resources/character_resource/plant_condition/000_common_plant_land.tres"),
		EnumsCharacter.PlantInfoAttribute.PlantScenes :  preload("res://scenes/character/plant/plant_1000_sprout.tscn")
		},

	## 保龄球
	EnumsCharacter.PlantType.P1001WallNutBowling: {
		EnumsCharacter.PlantInfoAttribute.PlantName: "WallNutBowling",
		EnumsCharacter.PlantInfoAttribute.CoolTime: 7.5,
		EnumsCharacter.PlantInfoAttribute.SunCost: 50,
		EnumsCharacter.PlantInfoAttribute.PlantConditionResource :  preload("res://resources/character_resource/plant_condition/000_common_plant_land.tres"),
		EnumsCharacter.PlantInfoAttribute.PlantScenes :  preload("res://scenes/character/plant/plant_1001_wall_nut_bowling.tscn")
		},
	EnumsCharacter.PlantType.P1002WallNutBowlingBomb: {
		EnumsCharacter.PlantInfoAttribute.PlantName: "WallNutBowlingBomb",
		EnumsCharacter.PlantInfoAttribute.CoolTime: 7.5,
		EnumsCharacter.PlantInfoAttribute.SunCost: 50,
		EnumsCharacter.PlantInfoAttribute.PlantConditionResource :  preload("res://resources/character_resource/plant_condition/000_common_plant_land.tres"),
		EnumsCharacter.PlantInfoAttribute.PlantScenes :  preload("res://scenes/character/plant/plant_1002_wall_nut_bowling.tscn")
		},
	EnumsCharacter.PlantType.P1003WallNutBowlingBig: {
		EnumsCharacter.PlantInfoAttribute.PlantName: "WallNutBowlingBig",
		EnumsCharacter.PlantInfoAttribute.CoolTime: 7.5,
		EnumsCharacter.PlantInfoAttribute.SunCost: 50,
		EnumsCharacter.PlantInfoAttribute.PlantConditionResource : preload("res://resources/character_resource/plant_condition/000_common_plant_land.tres"),
		EnumsCharacter.PlantInfoAttribute.PlantScenes : preload("res://scenes/character/plant/plant_1003_wall_nut_bowling.tscn")
		},
}


## 获取植物属性方法
func get_plant_info(plant_type:EnumsCharacter.PlantType, info_attribute:EnumsCharacter.PlantInfoAttribute):
	if plant_type == EnumsCharacter.PlantType.Null:
		print("warning:获取空植物信息")
		return null
	var curr_plant_info = PlantInfo[plant_type]
	return curr_plant_info[info_attribute]

#endregion

#region 僵尸
## 僵尸信息
const ZombieInfo = {
	EnumsCharacter.ZombieType.Z001Norm:{
		EnumsCharacter.ZombieInfoAttribute.ZombieName: "ZombieNorm",
		EnumsCharacter.ZombieInfoAttribute.CoolTime: 0.0,
		EnumsCharacter.ZombieInfoAttribute.SunCost: 50,
		EnumsCharacter.ZombieInfoAttribute.ZombieScenes:preload("res://scenes/character/zombie/zombie_001_norm.tscn"),
		EnumsCharacter.ZombieInfoAttribute.ZombieRowType:EnumsCharacter.ZombieRowType.Both
	},
	EnumsCharacter.ZombieType.Z002Flag:{
		EnumsCharacter.ZombieInfoAttribute.ZombieName: "ZombieFlag",
		EnumsCharacter.ZombieInfoAttribute.CoolTime: 0.0,
		EnumsCharacter.ZombieInfoAttribute.SunCost: 50,
		EnumsCharacter.ZombieInfoAttribute.ZombieScenes:preload("res://scenes/character/zombie/zombie_002_flag.tscn"),
		EnumsCharacter.ZombieInfoAttribute.ZombieRowType:EnumsCharacter.ZombieRowType.Both
	},
	EnumsCharacter.ZombieType.Z003Cone:{
		EnumsCharacter.ZombieInfoAttribute.ZombieName: "ZombieCone",
		EnumsCharacter.ZombieInfoAttribute.CoolTime: 0.0,
		EnumsCharacter.ZombieInfoAttribute.SunCost: 75,
		EnumsCharacter.ZombieInfoAttribute.ZombieScenes:preload("res://scenes/character/zombie/zombie_003_cone.tscn"),
		EnumsCharacter.ZombieInfoAttribute.ZombieRowType:EnumsCharacter.ZombieRowType.Both
	},
	EnumsCharacter.ZombieType.Z004PoleVaulter:{
		EnumsCharacter.ZombieInfoAttribute.ZombieName: "ZombiePoleVaulter",
		EnumsCharacter.ZombieInfoAttribute.CoolTime: 0.0,
		EnumsCharacter.ZombieInfoAttribute.SunCost: 75,
		EnumsCharacter.ZombieInfoAttribute.ZombieScenes:preload("res://scenes/character/zombie/zombie_004_pole_vaulter.tscn"),
		EnumsCharacter.ZombieInfoAttribute.ZombieRowType:EnumsCharacter.ZombieRowType.Land
	},
	EnumsCharacter.ZombieType.Z005Bucket:{
		EnumsCharacter.ZombieInfoAttribute.ZombieName: "ZombieBucket",
		EnumsCharacter.ZombieInfoAttribute.CoolTime: 0.0,
		EnumsCharacter.ZombieInfoAttribute.SunCost: 125,
		EnumsCharacter.ZombieInfoAttribute.ZombieScenes:preload("res://scenes/character/zombie/zombie_005_bucket.tscn"),
		EnumsCharacter.ZombieInfoAttribute.ZombieRowType:EnumsCharacter.ZombieRowType.Both
	},

	EnumsCharacter.ZombieType.Z006Paper:{
		EnumsCharacter.ZombieInfoAttribute.ZombieName: "ZombiePaper",
		EnumsCharacter.ZombieInfoAttribute.CoolTime: 0.0,
		EnumsCharacter.ZombieInfoAttribute.SunCost: 125,
		EnumsCharacter.ZombieInfoAttribute.ZombieScenes:preload("res://scenes/character/zombie/zombie_006_paper.tscn"),
		EnumsCharacter.ZombieInfoAttribute.ZombieRowType:EnumsCharacter.ZombieRowType.Land
	},
	EnumsCharacter.ZombieType.Z007ScreenDoor:{
		EnumsCharacter.ZombieInfoAttribute.ZombieName: "ZombieScreenDoor",
		EnumsCharacter.ZombieInfoAttribute.CoolTime: 0.0,
		EnumsCharacter.ZombieInfoAttribute.SunCost: 125,
		EnumsCharacter.ZombieInfoAttribute.ZombieScenes:preload("res://scenes/character/zombie/zombie_007_screendoor.tscn"),
		EnumsCharacter.ZombieInfoAttribute.ZombieRowType:EnumsCharacter.ZombieRowType.Land
	},
	EnumsCharacter.ZombieType.Z008Football:{
		EnumsCharacter.ZombieInfoAttribute.ZombieName: "ZombieFootball",
		EnumsCharacter.ZombieInfoAttribute.CoolTime: 0.0,
		EnumsCharacter.ZombieInfoAttribute.SunCost: 175,
		EnumsCharacter.ZombieInfoAttribute.ZombieScenes: preload("res://scenes/character/zombie/zombie_008_football.tscn"),
		EnumsCharacter.ZombieInfoAttribute.ZombieRowType:EnumsCharacter.ZombieRowType.Land
	},
	EnumsCharacter.ZombieType.Z009Jackson:{
		EnumsCharacter.ZombieInfoAttribute.ZombieName: "ZombieJackson",
		EnumsCharacter.ZombieInfoAttribute.CoolTime: 0.0,
		EnumsCharacter.ZombieInfoAttribute.SunCost: 300,
		EnumsCharacter.ZombieInfoAttribute.ZombieScenes:preload("res://scenes/character/zombie/zombie_009_jackson.tscn"),
		EnumsCharacter.ZombieInfoAttribute.ZombieRowType:EnumsCharacter.ZombieRowType.Land
	},
	EnumsCharacter.ZombieType.Z010Dancer:{
		EnumsCharacter.ZombieInfoAttribute.ZombieName: "ZombieDancer",
		EnumsCharacter.ZombieInfoAttribute.CoolTime: 0.0,
		EnumsCharacter.ZombieInfoAttribute.SunCost: 50,
		EnumsCharacter.ZombieInfoAttribute.ZombieScenes:preload("res://scenes/character/zombie/zombie_010_dancer.tscn"),
		EnumsCharacter.ZombieInfoAttribute.ZombieRowType:EnumsCharacter.ZombieRowType.Land
	},
	EnumsCharacter.ZombieType.Z011Duckytube:{
		EnumsCharacter.ZombieInfoAttribute.ZombieName: "ZombieDuckytube",
		EnumsCharacter.ZombieInfoAttribute.CoolTime: 0.0,
		EnumsCharacter.ZombieInfoAttribute.SunCost: 50,
		EnumsCharacter.ZombieInfoAttribute.ZombieScenes:preload("res://scenes/character/zombie/zombie_011_duckytube.tscn"),
		EnumsCharacter.ZombieInfoAttribute.ZombieRowType:EnumsCharacter.ZombieRowType.Both
	},
	EnumsCharacter.ZombieType.Z012Snorkle:{
		EnumsCharacter.ZombieInfoAttribute.ZombieName: "ZombieSnorkle",
		EnumsCharacter.ZombieInfoAttribute.CoolTime: 0.0,
		EnumsCharacter.ZombieInfoAttribute.SunCost: 75,
		EnumsCharacter.ZombieInfoAttribute.ZombieScenes:preload("res://scenes/character/zombie/zombie_012_snorkle.tscn"),
		EnumsCharacter.ZombieInfoAttribute.ZombieRowType:EnumsCharacter.ZombieRowType.Pool
	},
	EnumsCharacter.ZombieType.Z013Zamboni:{
		EnumsCharacter.ZombieInfoAttribute.ZombieName: "ZombieZamboni",
		EnumsCharacter.ZombieInfoAttribute.CoolTime: 0.0,
		EnumsCharacter.ZombieInfoAttribute.SunCost: 250,
		EnumsCharacter.ZombieInfoAttribute.ZombieScenes:preload("res://scenes/character/zombie/zombie_013_zamboni.tscn"),
		EnumsCharacter.ZombieInfoAttribute.ZombieRowType:EnumsCharacter.ZombieRowType.Land
	},
	EnumsCharacter.ZombieType.Z014Bobsled:{
		EnumsCharacter.ZombieInfoAttribute.ZombieName: "ZombieBobsled",
		EnumsCharacter.ZombieInfoAttribute.CoolTime: 0.0,
		EnumsCharacter.ZombieInfoAttribute.SunCost: 200,
		EnumsCharacter.ZombieInfoAttribute.ZombieScenes:preload("res://scenes/character/zombie/zombie_014_bobsled.tscn"),
		EnumsCharacter.ZombieInfoAttribute.ZombieRowType:EnumsCharacter.ZombieRowType.Land
	},
	EnumsCharacter.ZombieType.Z015Dolphinrider:{
		EnumsCharacter.ZombieInfoAttribute.ZombieName: "ZombieDolphinrider",
		EnumsCharacter.ZombieInfoAttribute.CoolTime: 0.0,
		EnumsCharacter.ZombieInfoAttribute.SunCost: 150,
		EnumsCharacter.ZombieInfoAttribute.ZombieScenes:preload("res://scenes/character/zombie/zombie_015_dolphinrider.tscn"),
		EnumsCharacter.ZombieInfoAttribute.ZombieRowType:EnumsCharacter.ZombieRowType.Pool
	},
	EnumsCharacter.ZombieType.Z016Jackbox:{
		EnumsCharacter.ZombieInfoAttribute.ZombieName: "ZombieJackbox",
		EnumsCharacter.ZombieInfoAttribute.CoolTime: 0.0,
		EnumsCharacter.ZombieInfoAttribute.SunCost: 75,
		EnumsCharacter.ZombieInfoAttribute.ZombieScenes:preload("res://scenes/character/zombie/zombie_016_jackbox.tscn"),
		EnumsCharacter.ZombieInfoAttribute.ZombieRowType:EnumsCharacter.ZombieRowType.Land
	},
	EnumsCharacter.ZombieType.Z017Balloon:{
		EnumsCharacter.ZombieInfoAttribute.ZombieName: "ZombieBallon",
		EnumsCharacter.ZombieInfoAttribute.CoolTime: 0.0,
		EnumsCharacter.ZombieInfoAttribute.SunCost: 75,
		EnumsCharacter.ZombieInfoAttribute.ZombieScenes:preload("res://scenes/character/zombie/zombie_017_balloon.tscn"),
		EnumsCharacter.ZombieInfoAttribute.ZombieRowType:EnumsCharacter.ZombieRowType.Both
	},
	EnumsCharacter.ZombieType.Z018Digger:{
		EnumsCharacter.ZombieInfoAttribute.ZombieName: "ZombieDigger",
		EnumsCharacter.ZombieInfoAttribute.CoolTime: 0.0,
		EnumsCharacter.ZombieInfoAttribute.SunCost: 125,
		EnumsCharacter.ZombieInfoAttribute.ZombieScenes:preload("res://scenes/character/zombie/zombie_018_digger.tscn"),
		EnumsCharacter.ZombieInfoAttribute.ZombieRowType:EnumsCharacter.ZombieRowType.Land
	},
	EnumsCharacter.ZombieType.Z019Pogo:{
		EnumsCharacter.ZombieInfoAttribute.ZombieName: "ZombiePogo",
		EnumsCharacter.ZombieInfoAttribute.CoolTime: 0.0,
		EnumsCharacter.ZombieInfoAttribute.SunCost: 125,
		EnumsCharacter.ZombieInfoAttribute.ZombieScenes:preload("res://scenes/character/zombie/zombie_019_pogo.tscn"),
		EnumsCharacter.ZombieInfoAttribute.ZombieRowType:EnumsCharacter.ZombieRowType.Land
	},
	EnumsCharacter.ZombieType.Z020Yeti:{
		EnumsCharacter.ZombieInfoAttribute.ZombieName: "ZombieYeti",
		EnumsCharacter.ZombieInfoAttribute.CoolTime: 0.0,
		EnumsCharacter.ZombieInfoAttribute.SunCost: 100,
		EnumsCharacter.ZombieInfoAttribute.ZombieScenes:preload("res://scenes/character/zombie/zombie_020_yeti.tscn"),
		EnumsCharacter.ZombieInfoAttribute.ZombieRowType:EnumsCharacter.ZombieRowType.Land
	},
	EnumsCharacter.ZombieType.Z021Bungi:{
		EnumsCharacter.ZombieInfoAttribute.ZombieName: "ZombieBungi",
		EnumsCharacter.ZombieInfoAttribute.CoolTime: 0.0,
		EnumsCharacter.ZombieInfoAttribute.SunCost: 125,
		EnumsCharacter.ZombieInfoAttribute.ZombieScenes:preload("res://scenes/character/zombie/zombie_021_bungi.tscn"),
		EnumsCharacter.ZombieInfoAttribute.ZombieRowType:EnumsCharacter.ZombieRowType.Both
	},
	EnumsCharacter.ZombieType.Z022Ladder:{
		EnumsCharacter.ZombieInfoAttribute.ZombieName: "ZombieLadder",
		EnumsCharacter.ZombieInfoAttribute.CoolTime: 0.0,
		EnumsCharacter.ZombieInfoAttribute.SunCost: 150,
		EnumsCharacter.ZombieInfoAttribute.ZombieScenes:preload("res://scenes/character/zombie/zombie_022_ladder.tscn"),
		EnumsCharacter.ZombieInfoAttribute.ZombieRowType:EnumsCharacter.ZombieRowType.Land
	},
	EnumsCharacter.ZombieType.Z023Catapult:{
		EnumsCharacter.ZombieInfoAttribute.ZombieName: "ZombieCatapult",
		EnumsCharacter.ZombieInfoAttribute.CoolTime: 0.0,
		EnumsCharacter.ZombieInfoAttribute.SunCost: 200,
		EnumsCharacter.ZombieInfoAttribute.ZombieScenes:preload("res://scenes/character/zombie/zombie_023_catapult.tscn"),
		EnumsCharacter.ZombieInfoAttribute.ZombieRowType:EnumsCharacter.ZombieRowType.Land
	},
	EnumsCharacter.ZombieType.Z024Gargantuar:{
		EnumsCharacter.ZombieInfoAttribute.ZombieName: "ZombieGargantuar",
		EnumsCharacter.ZombieInfoAttribute.CoolTime: 0.0,
		EnumsCharacter.ZombieInfoAttribute.SunCost: 300,
		EnumsCharacter.ZombieInfoAttribute.ZombieScenes:preload("res://scenes/character/zombie/zombie_024_gargantuar.tscn"),
		EnumsCharacter.ZombieInfoAttribute.ZombieRowType:EnumsCharacter.ZombieRowType.Land
	},
	EnumsCharacter.ZombieType.Z025Imp:{
		EnumsCharacter.ZombieInfoAttribute.ZombieName: "ZombieImp",
		EnumsCharacter.ZombieInfoAttribute.CoolTime: 0.0,
		EnumsCharacter.ZombieInfoAttribute.SunCost: 50,
		EnumsCharacter.ZombieInfoAttribute.ZombieScenes:preload("res://scenes/character/zombie/zombie_025_imp.tscn"),
		EnumsCharacter.ZombieInfoAttribute.ZombieRowType:EnumsCharacter.ZombieRowType.Land
	},

	## 单独雪橇僵尸
	EnumsCharacter.ZombieType.Z1001BobsledSingle:{
		EnumsCharacter.ZombieInfoAttribute.ZombieName: "ZombieBobsledSingle",
		EnumsCharacter.ZombieInfoAttribute.CoolTime: 0.0,
		EnumsCharacter.ZombieInfoAttribute.SunCost: 50,
		EnumsCharacter.ZombieInfoAttribute.ZombieScenes:preload("res://scenes/character/zombie/zombie_1001_bobsled_signle.tscn"),
		EnumsCharacter.ZombieInfoAttribute.ZombieRowType:EnumsCharacter.ZombieRowType.Land
	},
}

## 获取僵尸属性方法
func get_zombie_info(zombie_type:EnumsCharacter.ZombieType, info_attribute:EnumsCharacter.ZombieInfoAttribute):
	if zombie_type == 0:
		print("warning: 获取空僵尸信息")
		return null
	var curr_zombie_info = ZombieInfo[zombie_type]
	return curr_zombie_info[info_attribute]
