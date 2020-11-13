extends MarginContainer

# warning-ignore:unused_signal
signal returnToMainMenu

func _ready() -> void:
	default_state()
	print("Loaded locales: ", TranslationServer.get_loaded_locales())	

func start_ngrok(ngrok_path: String, ngrok_port: int, ngrok_auth_token: String = ""):
	match OS.get_name():
		"Windows":
			#str("start " + '""' + " http://www.stackoverflow.com")
			var cmd
			var output = []
			if ngrok_auth_token == "":
				cmd = OS.execute("cmd", ["/k", str(ngrok_path) + " http " + str(ngrok_port)], false, output)
			else:
				cmd = OS.execute("cmd", ["/k", str(ngrok_path) + " authtoken " + ngrok_auth_token, str(ngrok_path) + " http " + str(ngrok_port)], false)
			for i in output:
				print(i)
		"X11":
			pass
	#get url
	print("getting url")
	var output = []
	OS.execute("curl", ["http://localhost:4040/api/tunnels/command_line"], true, output)
	while JSON.parse(output[0]).get_result().keys().has("error_code"):
		#if output[0]["error_code"] != 100:
		#	break
		OS.execute("curl", ["http://localhost:4040/api/tunnels/command_line"], true, output)
	var response = JSON.parse(output[0]).get_result()
	for i in output:
		print(i)
	var ngrok_url = response.public_url
	print(ngrok_url)
	#var ngrok_url: String = ""
	#var http_request = HTTPRequest.new()
	#add_child(http_request)
	#var test = http_request.connect("request_completed", self, "_on_request_completed")
	#print(test)
	#var error = http_request.request("http://localhost:4040/api/tunnels", [], true, HTTPClient.METHOD_GET)#request("http://localhost:4040/api/tunnels/command_line")request("http://localhost:4040/api/tunnels")
	#print(error)

func _on_NewGame_pressed() -> void:
	start_ngrok("D:/Downloads/ngrok.exe", 42420)
	show_only("PlayGame")

func _on_Settings_pressed() -> void:
	show_only("Settings")

func _on_Return() -> void:
	default_state()

func default_state() -> void:
	show_only("MainMenu")

func show_only(element_name: String) -> void:
	return
	var element: Node = get_node(element_name)
	for child in get_children():
		child.visible = (child == element)

func _on_Quit_pressed() -> void:
	get_tree().quit()

func _on_Back_pressed() -> void:
	default_state()

func _on_MenuArea_returnToMainMenu():
	default_state()
