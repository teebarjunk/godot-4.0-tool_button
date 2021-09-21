extends HBoxContainer

var button = Button.new()
var object:Object
var info
var pluginref

func _init(obj:Object, d, p):
	object = obj
	pluginref = p
	
	if d is String:
		info = {"call": d}
	else:
		info = d
	
	alignment = BoxContainer.ALIGN_CENTER
	size_flags_horizontal = SIZE_EXPAND_FILL
	
	add_child(button)
	button.size_flags_horizontal = SIZE_EXPAND_FILL
	button.text = _get_label()
	button.modulate = info.get("tint", Color.WHITE)
	button.disabled = info.get("disabled", false)
	button.button_down.connect(self._on_button_pressed)
#	button.connect("pressed", self, "_on_button_pressed")
	
	button.hint_tooltip = "%s(%s)" % [info.call, _get_args_string()]
	
	if "hint" in info:
		button.hint_tooltip += "\n%s" % [info.hint]
	
	button.flat = info.get("flat", false)
	button.align  = info.get("align", Button.ALIGN_CENTER)
	
	if "icon" in info:
		button.expand_icon = false
		button.set_button_icon(load(info.icon))

func _get_args_string():
	if not "args" in info:
		return ""
	var args = ""
	for a in info.args:
		if not args == "":
			args += ", "
		if a is String:
			args += '"%s"' % [a]
		else:
			args += str(a)
	return args
		
func _get_label():
	if "text" in info:
		return info.text
	return info.call.capitalize()

func _on_button_pressed():
	var returned
	
	if "args" in info:
		returned = object.callv(info.call, info.args)
	else:
		returned = object.call(info.call)
	
	if info.get("print", true):
		var a = _get_args_string()
		if a:
			print(">> %s(%s): %s" % [info.call, a, returned])
		else:
			print(">> %s: %s" % [info.call, returned])
	
	if info.get("update_filesystem", false):
		pluginref.rescan_filesystem()
