extends EditorInspectorPlugin

var InspectorToolButton = preload("res://addons/tool_button/TB_Button.gd")
var pluginref
var default_node_signals := []
var default_resource_signals := []

func _init(p):
	pluginref = p
	default_node_signals = Node.new().get_signal_list()\
		.filter(func(m): return len(m.args) == 0)\
		.map(func(m): return m.name)
	default_resource_signals = Resource.new().get_signal_list()\
		.filter(func(m): return len(m.args) == 0)\
		.map(func(m): return m.name)

func _can_handle(object) -> bool:
	return true

# buttons defined in _get_tool_buttons show at the top
func _parse_begin(object: Object) -> void:
	if object.has_method("_get_tool_buttons"):
		var methods
		if object is Resource:
			methods = object.get_script()._get_tool_buttons()
		else:
			methods = object._get_tool_buttons()
		
		if methods:
			for method in methods:
				add_custom_control(InspectorToolButton.new(object, method, pluginref))

func _parse_category(object: Object, category: String) -> void:
	if not category in ["Node", "Resource"]:
		return
	
	var flags := {}
	if object.has_method("_get_tool_button_flags"):
		flags = object._get_tool_button_flags()
	
	var methods := object.get_method_list().filter(
		func(m: Dictionary):
			if m.flags & METHOD_FLAG_FROM_SCRIPT == 0:
				return false
			if m.name[0] == "@":
				return false
			if not flags.get("private", false) and m.name[0] in "_":
				return false
			if not flags.get("getters", true) and m.name.begins_with("get_"):
				return false
			if not flags.get("setters", false) and m.name.begins_with("set_"):
				return false
			return true
	)
	# sort on name
	methods.sort_custom(func(a, b): return a.name < b.name)
	for method in methods:
		add_custom_control(InspectorToolButton.new(object, {
			tint=Color.PALE_TURQUOISE,
			call=method.name,
		}, pluginref))
	
	var signals = object.get_signal_list().filter(func(s): return len(s.args) == 0)
	if category == "Node":
		signals = signals.filter(func(s): return not s.name in default_node_signals)
	elif category == "Resource":
		signals = signals.filter(func(s): return not s.name in default_resource_signals)
	
	signals.sort_custom(func(a, b): return a.name < b.name)
	for sig in signals:
		add_custom_control(InspectorToolButton.new(object, {
			tint=Color.PALE_GOLDENROD,
			call=sig.name
		}, pluginref))
