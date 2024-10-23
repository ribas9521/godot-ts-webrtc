extends Node2D

@export var players_container: Node2D
@export var player_scene: PackedScene
@export var spawn_points: Node2D

var player_i = 0

func _ready()-> void:
	print(multiplayer.is_server())
	var players = multiplayer.get_peers()
	players.append(multiplayer.get_unique_id())
	players.sort()
	print(players)
	for player in players:
		add_player(player, player_i)
		player_i = player_i + 1
	
	
	
func _exit_tree():
	if not multiplayer.is_server():
		return
	multiplayer.peer_disconnected.disconnect(delete_player)
	
func add_player(id, player_i):
	print("ADDING PLAYER", id)
	if players_container.has_node(str(id)):
		return
	
	var player_instance = player_scene.instantiate()
	player_instance.name = str(id)
	var player_instance_x = 0
	if player_i > 0:
		player_instance_x = player_i * 150
		
	player_instance.position = Vector2(player_instance_x, 0)
	print(player_instance.position )
	players_container.add_child(player_instance)
	
 
func delete_player(id):
	if not players_container.has_node(str(id)):
		return
	
	players_container.get_node(str(id)).queue_free()
