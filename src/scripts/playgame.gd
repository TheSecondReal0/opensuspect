extends VBoxContainer

export (NodePath) var Back = ""
export (NodePath) var JoinGameDialog = ""
export (NodePath) var HostnameField = ""
export (NodePath) var PortField = ""
export (NodePath) var CreatePortField = ""
export (NodePath) var CreateGameDialog = ""
export (String, FILE, "*.tscn") var main = ""

func _ready():
	Back = get_node(Back)
	JoinGameDialog = get_node(JoinGameDialog)
	HostnameField = get_node(HostnameField)
	PortField = get_node(PortField)
	CreatePortField = get_node(CreatePortField)
	CreateGameDialog = get_node(CreateGameDialog)
	Back.connect("pressed", get_node(".."), "_on_Return")

func _on_JoinGame_pressed():
	JoinGameDialog.popup()

func _on_Connect_pressed():
	Network.connection = Network.Connection.CLIENT
	Network.host = HostnameField.text
	Network.port = PortField.text
	get_tree().change_scene(main)

func _on_Create_pressed():
	Network.connection = Network.Connection.CLIENT_SERVER
	Network.host = 'localhost'
	Network.port = PortField.text
	get_tree().change_scene(main)

func _on_CreateGame_pressed():
	CreateGameDialog.popup()
