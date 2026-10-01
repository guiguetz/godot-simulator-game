extends SceneTree
## Testa se o TileMapDual está funcionando corretamente.
## Execute com: godot --headless --path . --script tools/test_tilemapdual.gd

func _init() -> void:
	print("Testing TileMapDual...")
	
	# Load the scene
	var scene := load("res://scenes/game.tscn") as PackedScene
	if scene == null:
		push_error("Failed to load scene")
		quit()
		return
	
	# Instantiate the scene
	var root := scene.instantiate()
	if root == null:
		push_error("Failed to instantiate scene")
		quit()
		return
	
	# Check if TileMapDual nodes exist
	var water := root.get_node_or_null("TerrainWater")
	var dirt := root.get_node_or_null("TerrainDirt")
	var soil := root.get_node_or_null("TerrainSoil")
	
	if water == null:
		push_error("TerrainWater not found")
	else:
		print("PASS: TerrainWater exists")
	
	if dirt == null:
		push_error("TerrainDirt not found")
	else:
		print("PASS: TerrainDirt exists")
	
	if soil == null:
		push_error("TerrainSoil not found")
	else:
		print("PASS: TerrainSoil exists")
	
	# Check if nodes have TileMapDual script
	var tilemapdual_script := load("res://addons/TileMapDual/tile_map_dual.gd")
	if water and water.get_script() == tilemapdual_script:
		print("PASS: TerrainWater has TileMapDual script")
	else:
		push_error("FAIL: TerrainWater does not have TileMapDual script")
	
	if dirt and dirt.get_script() == tilemapdual_script:
		print("PASS: TerrainDirt has TileMapDual script")
	else:
		push_error("FAIL: TerrainDirt does not have TileMapDual script")
	
	if soil and soil.get_script() == tilemapdual_script:
		print("PASS: TerrainSoil has TileMapDual script")
	else:
		push_error("FAIL: TerrainSoil does not have TileMapDual script")
	
	# Check if nodes have TileSets
	if water and water.tile_set:
		print("PASS: TerrainWater has TileSet")
	else:
		push_error("FAIL: TerrainWater does not have TileSet")
	
	if dirt and dirt.tile_set:
		print("PASS: TerrainDirt has TileSet")
	else:
		push_error("FAIL: TerrainDirt does not have TileSet")
	
	if soil and soil.tile_set:
		print("PASS: TerrainSoil has TileSet")
	else:
		push_error("FAIL: TerrainSoil does not have TileSet")
	
	print("TileMapDual test complete!")
	quit()