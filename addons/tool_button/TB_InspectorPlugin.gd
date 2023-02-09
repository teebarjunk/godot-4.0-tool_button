extends EditorInspectorPlugin

var InspectorToolButton = preload("res://addons/tool_button/TB_Button.gd")
var pluginref
var default_node_signals := []
var default_resource_signals := []

const ALLOW_NODE_METHODS := [
	"get_class", "get_path", "raise", "get_groups",
	"get_owner", "get_process_priority", "get_scene_file_path"
]
const ALLOW_RESOURCE_METHODS := [
	"get_class", "get_path"
]
const BLOCK_RESOURCE_SIGNALS := [
	"setup_local_to_scene_requested"
]

var inherited_method_list = []
func _init(p):
	pluginref = p
	default_node_signals = Node.new().get_signal_list()\
		.filter(func(m): return len(m.args) == 0)\
		.map(func(m): return m.name)
	default_resource_signals = Resource.new().get_signal_list()\
		.filter(func(m): return len(m.args) == 0)\
		.map(func(m): return m.name)

	inherited_method_list += Node.new().get_method_list()
	inherited_method_list += Node2D.new().get_method_list()
	inherited_method_list += Control.new().get_method_list()

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

var object_category_cache = []
func _parse_category(object: Object, category: String) -> void:
	var allowed_categories = []
	if ProjectSettings.get_setting("show_default_buttons"):
		allowed_categories = ["Node", "Resource"]

#	var obj_script = object.get_script()
#	if obj_script:
#		var has_exports = "@export" in obj_script.source_code
#		var attached_script_category = ""
#		if has_exports:
#			attached_script_category = obj_script.resource_path.get_file()
#			object_category_cache.append(attached_script_category)
#			allowed_categories.append(attached_script_category)

	if not category in allowed_categories:
		return

	var flags := {}
	if object.has_method("_get_tool_button_flags"):
		flags = object._get_tool_button_flags()

	var methods := object.get_method_list().filter(
		func(m: Dictionary):
			if m in inherited_method_list:
				return false
			if m.name[0] == "@":
				return false
			if not flags.get("private", false) and m.name[0] in "_":
				return false
			if not flags.get("getters", false) and m.name.begins_with("get_"):
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

	if category == "Node":
		for method in ALLOW_NODE_METHODS:
			add_custom_control(InspectorToolButton.new(object, {
				tint=Color.PALE_TURQUOISE.lerp(Color.DARK_GRAY, .5),
				call=method,
			}, pluginref))
	elif category == "Resource":
		for method in ALLOW_RESOURCE_METHODS:
			add_custom_control(InspectorToolButton.new(object, {
				tint=Color.PALE_TURQUOISE.lerp(Color.DARK_GRAY, .5),
				call=method,
			}, pluginref))

	var parent_signals = ClassDB.class_get_signal_list(ClassDB.get_parent_class(object.get_class()))\
		.filter(func(s): return len(s.args) == 0)\
		.map(func(x): return x.name)
	parent_signals.sort_custom(func(a, b): return a < b)

	var signals = object.get_signal_list()\
		.filter(func(s): return len(s.args) == 0 and not s.name in parent_signals)\
		.map(func(x): return x.name)
	if category == "Node":
		signals = signals.filter(func(x): return not x in default_node_signals)
	elif category == "Resource":
		signals = signals.filter(func(x): return not x in default_resource_signals)

	signals.sort_custom(func(a, b): return a < b)

	for sig in signals:
		add_custom_control(InspectorToolButton.new(object, {
			tint=Color.PALE_GOLDENROD,
			call=sig
		}, pluginref))

	if category == "Node":
		parent_signals = parent_signals.filter(func(x): return not x in default_node_signals)
	elif category == "Resource":
		parent_signals = parent_signals.filter(func(x): return not x in default_resource_signals)

	for sig in parent_signals:
		add_custom_control(InspectorToolButton.new(object, {
			tint=Color.PALE_GOLDENROD.lerp(Color.DARK_GRAY, .5),
			call=sig
		}, pluginref))
