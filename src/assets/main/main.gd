extends Node2D

export (int) var MAX_PLAYERS = 10
export (String, FILE, "*.tscn") var player_s = "res://assets/player/player.tscn"
var player_scene = load(player_s)
#onready var player_scene = preload(player_s)
# Used on both sides, to keep track of all players.
var players = {}
#!!!THIS IS IMPORTANT!!!
#INCREASE THIS VARIABLE BY ONE EVERY COMMIT TO PREVENT OLD CLIENTS FROM TRYING TO CONNECT TO SERVERS!!!
var version = 10
var intruders = 0
var newnumber
var spawn_pos = Vector2(0,0)
func _ready():
	set_network_master(1)

# Gets called when the title scene sets this scene as the main scene
func _enter_tree():
	if Network.connection == Network.Connection.CLIENT_SERVER:
# warning-ignore:return_value_discarded
		get_tree().connect("network_peer_disconnected", self, "_player_disconnected")
# warning-ignore:return_value_discarded
		Network.connect("connection_handled", self, "connection_handled")
		PlayerManager.ournumber = 0
		createPlayer(Network.get_my_id(), Network.get_player_name())
	elif Network.connection == Network.Connection.CLIENT:
# warning-ignore:return_value_discarded
		get_tree().connect("network_peer_disconnected", self, "_player_disconnected")

# Keep the clients' player positions updated
func _physics_process(_delta):
	if get_tree().is_network_server():
		var positions_dict = {}
		for id in players.keys():
			positions_dict[id] = [players[id].position, players[id].movement]
		rpc("update_positions", positions_dict)

func connection_handled(id, playerName):
	print("connection handled, id: ", id, " name: ", playerName)
	if not get_tree().is_network_server():
		return
	rpc("checkVersion", version)
	newnumber = Network.peers.size()
	rpc_id(id, "receiveNumber", newnumber)
	#tell all existing players to create this player
	for i in players.keys():
		if i != id:
			print("telling ", i, " to create player ", id)
			rpc_id(i, "createPlayer", id, playerName, spawn_pos)
	#tell new player to create existing players
	print("telling ", id, " to create players")
	rpc_id(id, "createPlayers", Network.get_player_names())

puppet func checkVersion(sversion):
	if version != sversion:
		print("HEY! YOU! YOU FORGOT TO UPDATE YOUR CLIENT. RE EXPORT AND TRY AGAIN!")

puppet func receiveNumber(number):
	if get_tree().get_rpc_sender_id() != 1:
		return
	PlayerManager.ournumber = number

func _player_disconnected(id):
	players[id].queue_free() #deletes player node when a player disconnects
	players.erase(id)

#idNameDict should look like {<network ID>: <player name>}
puppetsync func createPlayers(idNameDict: Dictionary, spawnPointDict: Dictionary = {}):
	deletePlayers()
	for i in idNameDict.keys():
		if spawnPointDict.keys().has(i):
			#spawn at spawn point
			createPlayer(i, idNameDict[i], spawnPointDict[i])
		else:
			#else spawn at default spawn
			createPlayer(i, idNameDict[i], spawn_pos)

puppetsync func createPlayer(id: int, playerName: String, spawnPoint: Vector2 = Vector2(0,0)):
	print("creating player ", id)
	if players.keys().has(id):
		print("not creating player, already exists")
		return
	var newPlayer = player_scene.instance()
	newPlayer.id = id
	newPlayer.setName(playerName)
	#newPlayer.set_network_master(id)
	if id == Network.get_my_id():
		newPlayer.main_player = true
		newPlayer.connect("main_player_moved", self, "_on_main_player_moved")
	players[id] = newPlayer
	$players.add_child(newPlayer)
	newPlayer.move_to(spawnPoint, Vector2(0,0))
	print("New player: ", id)
	#_on_maps_spawn(spawn_pos, recentmap)

func deletePlayers():
	for i in players.keys():
		players[i].queue_free()
	players.clear()

# Called from client side to tell the server about the player's actions
remote func player_moved(new_movement):
	# Should only be run on the server
	if !get_tree().is_network_server():
		return
	var id = get_tree().get_rpc_sender_id()
	#print(id)
	#print("Got player move from ", id) #no reason to spam console so much
	if not players.keys().has(id):
		return
	# Check movement validity
	if new_movement.length() > 1:
		new_movement = new_movement.normalized()
	players[id].movement = new_movement

# Called from server when the server's players move
puppet func update_positions(positions_dict):
	for id in positions_dict.keys():
		if players.keys().has(id):
			players[id].move_to(positions_dict[id][0], positions_dict[id][1])

func _on_main_player_moved(movement : Vector2):
	if not get_tree().is_network_server():
		rpc_id(1, "player_moved", movement)

master func _on_maps_spawn(spawnPos, _frommap):
	#print("spawnPos: ", spawnPos)
	if not get_tree().is_network_server():
		return
	spawn_pos = spawnPos
	#generate spawn point dict
	var spawnPointDict: Dictionary = {}
	for i in players.keys().size():
		spawnPointDict[players.keys()[i]] = Vector2(spawnPos.x+(i*80), spawnPos.y)
	#spawn players
	rpc("createPlayers", Network.get_player_names(), spawnPointDict)
