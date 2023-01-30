extends HBoxContainer

var all_info := []
var check: CheckBox
var object: Object
var pluginref: EditorPlugin
var hash_id: int

# @SCAN
# @CREATE_AND_EDIT;file_path;text
# @SELECT_AND_EDIT;file_path
# @SELECT_FILE;file_path
# @EDIT_RESOURCE;file_path

const TINT_METHOD := Color.PALE_TURQUOISE
const TINT_SIGNAL := Color.PALE_GOLDENROD

func _init(obj: Object, d, p):
	object = obj
	pluginref = p
	hash_id = hash(d)

	alignment = BoxContainer.ALIGNMENT_CENTER
	size_flags_horizontal = SIZE_EXPAND_FILL

	var got = _get_info(d)
	all_info = [got] if got is Dictionary else got

	for index in len(all_info):
		var info: Dictionary = all_info[index]

		var button := Button.new()
		add_child(button)
		button.size_flags_horizontal = SIZE_EXPAND_FILL
		button.text = info.text
		button.modulate = _get_key_or_call(info, "tint", TYPE_COLOR, Color.WHITE)
		button.disabled = _get_key_or_call(info, "lock", TYPE_BOOL, false)

		button.button_down.connect(self._on_button_pressed.bind(index))

		if "hint" in info:
			button.tooltip_text = _get_key_or_call(info, "hint", TYPE_STRING, "")
		else:
			button.tooltip_text = "%s(%s)" % [info.call, _get_args_string(info)]

		button.flat = info.get("flat", false)
		button.alignment = info.get("align", HORIZONTAL_ALIGNMENT_CENTER)

		if "icon" in info:
			button.expand_icon = false
			button.set_button_icon(load(_get_key_or_call(info, "icon", TYPE_STRING, "")))

	# add a check box if there are multiple buttons
	if len(all_info) > 1:
		check = CheckBox.new()
		check.button_pressed = _get_tool_button_state().get(hash_id, false)
		check.tooltip_text = "All at once"
		check.pressed.connect(_check_pressed)
		add_child(check)

func _get_tool_button_state() -> Dictionary:
	if not object.has_meta("tool_button_state"):
		object.set_meta("tool_button_state", {})
	return object.get_meta("tool_button_state")

func _check_pressed():
	var d := _get_tool_button_state()
	d[hash_id] = check.button_pressed

func _get_info(d: Variant) -> Variant:
	var out := {}

	if d is String:
		out.call = d
		out.text = d

	elif d is Callable:
		if d.is_custom():
			out.call = d
			out.text = str(d)
			if "::" in out.text:
				out.text = out.text.split("::")[-1]
			if "(lambda)" in out.text:
				out.text = out.text.replace("(lambda)", "")

			if d.get_object() != null and d.get_object().has_method(out.text):
				out.tint = TINT_METHOD

			out.text = out.text.capitalize()

		else:
			out.call = d
			out.text = str(d.get_method()).capitalize()
			out.tint = TINT_METHOD

	elif d is Signal:
		out.call = _do_signal.bind([d, []])
		out.text = str(d.get_name()).capitalize()
		out.tint = TINT_SIGNAL
		out.hint = str(d)

	elif d is Array:
		if d[0] is Signal:
			var sig: Signal = d[0]
			var args = " ".join(d[1].map(func(x): return str(x)))
			out.call=_do_signal.bind(d)
			out.text="%s\n%s" % [str(sig.get_name()).capitalize(), args]
			out.tint=TINT_SIGNAL
			out.hint=str(sig)

		else:
			var out_list := []
			for item in d:
				out_list.append(_get_info(item))
			return out_list

	elif d is Dictionary:
		out = d

		if not "text" in out:
			out.text = str(out.call)

	else:
		print("Hmm 0?", d)

	_process_info(out)
	return out

func _process_info(out: Dictionary):
	if not "call" in out:
		var s = str(out)
		out.call = func(): print("No call defined for %s." % s)

	# special tags of extra actions
	var parts := Array(_get_label(out).split(";"))
	if out.call is String:
		out.call = parts[0]
		out.text = parts.pop_front().capitalize()
	else:
		out.text = parts.pop_front()

	# was just a string passed?
	if out.call is String:
		# was it a method?
		if object.has_method(out.call):
			if not "tint" in out:
				out.tint = TINT_METHOD

		# was it a signal?
		elif object.has_signal(out.call):
			if not "tint" in out:
				out.tint = TINT_SIGNAL

	for i in len(parts):
		if parts[i].begins_with("!"):
			var tag: String = parts[i].substr(1)
			var clr := Color()
			out.tint = clr.from_string(tag, Color.SLATE_GRAY)

	return out

func _do_signal(sig_args: Array):
	var sig: Signal = sig_args[0]
	var args: Array = sig_args[1]
	match len(args):
		0: sig.emit()
		1: sig.emit(args[0])
		2: sig.emit(args[0], args[1])
		3: sig.emit(args[0], args[1], args[2])
		4: sig.emit(args[0], args[1], args[2], args[3])
		5: sig.emit(args[0], args[1], args[2], args[3], args[4])
		6: sig.emit(args[0], args[1], args[2], args[3], args[4], args[5])
		_: push_error("Not implemented.")

func _get_label(x: Variant) -> String:
	if x is String:
		return x.capitalize()
	elif x is Callable:
		return str(x.get_method()).capitalize()
	elif x is Dictionary:
		if "text" in x:
			if x.text is String:
				return x.text
			elif x.text is Callable:
				return x.text.call()
			else:
				return str(x.text)
		else:
			return _get_label(x.call)
	else:
		return "???"

func _get_key_or_call(info: Dictionary, k: String, t: int, default):
	if k in info:
		if typeof(info[k]) == t:
			return info[k]
		elif info[k] is Callable:
			return info[k].call()
		else:
			print("TB_BUTTON: Shouldn't happen.")
	else:
		return default

func _get_args_string(info: Dictionary):
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

func _call(x: Variant) -> Variant:
	if x is Dictionary:
		return _call(x.call)

	elif x is Callable:
#		prints(x.get_object(), x.get_object_id(), x.is_custom(), x.is_null(), x.is_standard(), x.is_valid())
		var got = x.call()
#		if x.is_custom():
#			return get_error_name(got)
		return got

	elif x is Array:
		var out := []
		for item in x:
			out.append(_call(item))
		return out

	elif x is String:
		# special internal editor actions.
		if x.begins_with("@"):
			var p = x.substr(1).split(";")
			match p[0]:
				"SCAN":
					pluginref.get_editor_interface().get_resource_filesystem().scan()

				"CREATE_AND_EDIT":
					var f = FileAccess.open(p[1], FileAccess.WRITE)
					f.store_string(p[2])
					f.close()
					var rf: EditorFileSystem = pluginref.get_editor_interface().get_resource_filesystem()
					rf.update_file(p[1])
					rf.scan()
					rf.scan_sources()

					pluginref.get_editor_interface().select_file(p[1])
					pluginref.get_editor_interface().edit_resource.call_deferred(load(p[1]))

				"SELECT_AND_EDIT":
					if FileAccess.file_exists(p[1]):
						pluginref.get_editor_interface().select_file(p[1])
						pluginref.get_editor_interface().edit_resource.call_deferred(load(p[1]))
					else:
						push_error("Nothing to select and edit at %s." % p[1])

				"SELECT_FILE":
					if FileAccess.file_exists(p[1]):
						pluginref.get_editor_interface().select_file(p[1])
					else:
						push_error("No file to select at %s." % p[1])

				"EDIT_RESOURCE":
					if FileAccess.file_exists(p[1]):
						pluginref.get_editor_interface().edit_resource.call_deferred(load(p[1]))
					else:
						push_error("No resource to edit at %s." % p[1])

			return null

		else:
			# as method
			if object.has_method(x):
				return object.call(x)

			# as signal
			elif object.has_signal(x):
				var error := object.emit_signal(x)
				var err_name := get_error_name(error)
				return "%s: %s (signal)" % [err_name, x]

			else:
				push_error("Hmm 1?")
				return null
	else:
		push_error("Hmm 2?")
		return null

func _edit(file: String):
	pluginref.get_editor_interface().select_file(file)
	pluginref.get_editor_interface().edit_resource.call_deferred(ResourceLoader.load(file, "TextFile", 0))

func _on_button_pressed(index: int):
	var got
	if check and check.button_pressed:
		got = []
		for info in all_info:
			got.append(_call(info))
	else:
		got = _call(all_info[index])
	if got != null:
		print("[tool_button]: ", got)

static func get_error_name(error: int) -> String:
	match error:
		OK: return "Okay"
		FAILED: return "Generic"
		ERR_UNAVAILABLE: return "Unavailable"
		ERR_UNCONFIGURED: return "Unconfigured"
		ERR_UNAUTHORIZED: return "Unauthorized"
		ERR_PARAMETER_RANGE_ERROR: return "Parameter range"
		ERR_OUT_OF_MEMORY: return "Out of memory (OOM)"
		ERR_FILE_NOT_FOUND: return "File: Not found"
		ERR_FILE_BAD_DRIVE: return "File: Bad drive"
		ERR_FILE_BAD_PATH: return "File: Bad path"
		ERR_FILE_NO_PERMISSION: return "File: No permission"
		ERR_FILE_ALREADY_IN_USE: return "File: Already in use"
		ERR_FILE_CANT_OPEN: return "File: Can't open"
		ERR_FILE_CANT_WRITE: return "File: Can't write"
		ERR_FILE_CANT_READ: return "File: Can't read"
		ERR_FILE_UNRECOGNIZED: return "File: Unrecognized"
		ERR_FILE_CORRUPT: return "File: Corrupt"
		ERR_FILE_MISSING_DEPENDENCIES: return "File: Missing dependencies"
		ERR_FILE_EOF: return "File: End of file (EOF)"
		ERR_CANT_OPEN: return "Can't open"
		ERR_CANT_CREATE: return "Can't create"
		ERR_QUERY_FAILED: return "Query failed"
		ERR_ALREADY_IN_USE: return "Already in use"
		ERR_LOCKED: return "Locked"
		ERR_TIMEOUT: return "Timeout"
		ERR_CANT_CONNECT: return "Can't connect"
		ERR_CANT_RESOLVE: return "Can't resolve"
		ERR_CONNECTION_ERROR: return "Connection"
		ERR_CANT_ACQUIRE_RESOURCE: return "Can't acquire resource"
		ERR_CANT_FORK: return "Can't fork process"
		ERR_INVALID_DATA: return "Invalid data"
		ERR_INVALID_PARAMETER: return "Invalid parameter"
		ERR_ALREADY_EXISTS: return "Already exists"
		ERR_DOES_NOT_EXIST: return "Does not exist"
		ERR_DATABASE_CANT_READ: return "Database: Read"
		ERR_DATABASE_CANT_WRITE: return "Database: Write"
		ERR_COMPILATION_FAILED: return "Compilation failed"
		ERR_METHOD_NOT_FOUND: return "Method not found"
		ERR_LINK_FAILED: return "Linking failed"
		ERR_SCRIPT_FAILED: return "Script failed"
		ERR_CYCLIC_LINK: return "Cycling link (import cycle)"
		ERR_INVALID_DECLARATION: return "Invalid declaration"
		ERR_DUPLICATE_SYMBOL: return "Duplicate symbol"
		ERR_PARSE_ERROR: return "Parse"
		ERR_BUSY: return "Busy"
		ERR_SKIP: return "Skip"
		ERR_HELP: return "Help"
		ERR_BUG: return "Bug"
		ERR_PRINTER_ON_FIRE: return "Printer on fire. (This is an easter egg, no engine methods return this error code.)"
		_: return "ERROR %s???" % error
