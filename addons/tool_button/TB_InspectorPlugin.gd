extends EditorInspectorPlugin

var InspectorToolButton = preload("res://addons/tool_button/TB_Button.gd")
var pluginref

#var _object:Object
#var _cache_methods:Dictionary = {}
#var _cache_selected:Dictionary = {}

func _init(p):
	pluginref = p

func _can_handle(object) -> bool:
	return true

#func _can_handle(object):
#	_object = object
#	_cache_methods[object] = _collect_methods(object)
#	return _cache_methods[object] or object.has_method("_get_tool_buttons")

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
	match category:
		"Node", "Resource":
			for method in _get_methods(category):
				add_custom_control(InspectorToolButton.new(object, {
					tint=Color.GREEN_YELLOW,
					call=method.name,
					print=true,
					update_filesystem=true
				}, pluginref))

func _get_methods(object:String) -> Array:
	var methods = ClassDB.class_get_method_list(object, true)
	var out = []
	for i in len(methods):
		var m:Dictionary = methods[i]
		var n:String = methods[i].name
		
		if n.begins_with("_") or n.begins_with("set_") or n.begins_with("get_"):
			continue
		
		if n in ["queue_free", "duplicate", "create_tween", "print_stray_nodes", "remove_and_skip"]:
			continue
		
		if len(m.args) != len(m.default_args):
			continue
		
		out.append(m)
	
	out.sort_custom(func(a, b): return a.name < b.name)
	return out
