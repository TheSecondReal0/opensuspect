extends WindowDialog

var targetTime: int = 433
var currentTime: int = 630

onready var hoursNode: Node = get_node("clock/hours")
onready var minutesNode: Node = get_node("clock/minutes")
onready var ampmNode: Node = get_node("clock/ampm")

func _ready():
	hoursNode.get_line_edit().connect("focus_entered", self, "_on_hours_focus_entered")
	minutesNode.get_line_edit().connect("focus_entered", self, "_on_minutes_focus_entered")
	ampmNode.get_line_edit().connect("focus_entered", self, "_on_ampm_focus_entered")
	setWatchTime(targetTime)
	setClockTime(currentTime)
	popup()

func checkComplete():
	if targetTime == currentTime:
		taskComplete()

func taskComplete():
	pass

func setClockTime(newTime):
	hoursNode.value = roundDown(newTime / 100, 1)
	minutesNode.value = newTime % 100

func setWatchTime(newTime):
	$watch/watchface.showTime(newTime)

func roundDown(num, step):
	var normRound = stepify(num, step)
	if normRound > num:
		return normRound - step
	return normRound

func _on_hours_value_changed(value):
	if value == 0:
		hoursNode.value = 12
	if value == 13:
		hoursNode.value = 1

func _on_minutes_value_changed(value):
	if value == -1:
		minutesNode.value = 59
		value = 59
	if value == 60:
		minutesNode.value = 0
		value = 0
	if value < 10:
		minutesNode.prefix = "0" + str(value) + "       "
	else:
		minutesNode.prefix = ""

func _on_ampm_value_changed(value):
	#allowing rollover
	if value == -1:
		ampmNode.value = 1
		value = 1
	if value == 2:
		ampmNode.value = 0
		value = 0
	#making it show AM or PM
	if value == 0:
		 #added spaces so the number doesn't show up in spinbox
		ampmNode.prefix = "AM" + "     "
	else:
		#added spaces so the number doesn't show up in spinbox
		ampmNode.prefix = "PM" + "     "

#so you can't type into the spinboxes
func _on_hours_focus_entered():
	grab_focus()

func _on_minutes_focus_entered():
	grab_focus()

func _on_ampm_focus_entered():
	grab_focus()