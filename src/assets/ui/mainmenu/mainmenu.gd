extends MarginContainer

# warning-ignore:unused_signal
signal returnToMainMenu

func _ready() -> void:
	default_state()
	print("Loaded locales: ", TranslationServer.get_loaded_locales())
	start_ngrok("D:/Downloads/ngrok.exe", 42420)
	

func start_ngrok(ngrok_path: String, ngrok_port: int, ngrok_auth_token: String = ""):
	match OS.get_name():
		"Windows":
			#str("start " + '""' + " http://www.stackoverflow.com")
			var cmd
			if ngrok_auth_token == "":
				cmd = OS.execute("CMD.exe", [str(ngrok_path) + " http " + str(ngrok_port)], false)
			else:
				cmd = OS.execute("CMD.exe", [str(ngrok_path) + " authtoken " + ngrok_auth_token, str(ngrok_path) + " http " + str(ngrok_port)], false)
			print(cmd)
		"X11":
			pass
	#get url
	print("getting url")
	var ngrok_url: String = ""
	var http_request = HTTPRequest.new()
	add_child(http_request)
	var test = http_request.connect("request_completed", self, "_on_request_completed")
	print(test)
	var error = http_request.request("http://localhost:4040/api/tunnels/command_line")#request("http://www.mocky.io/v2/5185415ba171ea3a00704eed")request("http://localhost:4040/api/tunnels/command_line")
	print(error)

func _on_request_completed(result, response_code, headers, body):
	print("got url")
	var json = JSON.parse(body.get_string_from_utf8())
	print(result)
	print(json[result])

func _on_NewGame_pressed() -> void:
	show_only("PlayGame")

func _on_Settings_pressed() -> void:
	show_only("Settings")

func _on_Return() -> void:
	default_state()

func default_state() -> void:
	show_only("MainMenu")

func show_only(element_name: String) -> void:
	var element: Node = get_node(element_name)
	for child in get_children():
		child.visible = (child == element)

func _on_Quit_pressed() -> void:
	get_tree().quit()

func _on_Back_pressed() -> void:
	default_state()

func _on_MenuArea_returnToMainMenu():
	default_state()
