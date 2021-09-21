extends EditorInspectorPlugin

var InspectorToolButton = preload("res://addons/tool_button/TB_Button.gd")
var pluginref

var _object:Object
var _cache_methods:Dictionary = {}
var _cache_selected:Dictionary = {}

func _init(p):
	pluginref = p
	
func _can_handle(object):
	_object = object
	_cache_methods[object] = _collect_methods(object)
	return _cache_methods[object] or object.has_method("_get_tool_buttons")

# buttons at bottom of inspector
func _parse_category(object, category):
	match category:
		"Node", "Resource":
			if _cache_methods[object]:
				for method in _cache_methods[object]:
					add_custom_control(InspectorToolButton.new(object, {
						tint=Color.GREEN_YELLOW,
						call=method,
						print=true,
						update_filesystem=true
					}, pluginref))

# buttons defined in _get_tool_buttons show at the top
func _parse_begin():
	if _object.has_method("_get_tool_buttons"):
		var methods
		if _object is Resource:
			methods = _object.get_script()._get_tool_buttons()
		else:
			methods = _object._get_tool_buttons()
		
		if methods:
			for method in methods:
				add_custom_control(InspectorToolButton.new(_object, method, pluginref))

func _allow_method(name:String) -> bool:
	return not name.begins_with("_")\
		and not name.begins_with("set_")\
		and not name.begins_with("@")

func _collect_methods(object:Object) -> Array:
	var script = object.get_script()
	if not script or not script.is_tool():
		return []
	
	var default_methods = []
	
	# ignore methods of parent
	if object is Resource:
		for m in ClassDB.class_get_method_list(object.get_script().get_class()):
			default_methods.append(m.name)
	else:
		for m in ClassDB.class_get_method_list(object.get_class()):
			default_methods.append(m.name)
	
	var methods = []
	for m in object.get_method_list():
		if not m.name in default_methods:
			if _allow_method(m.name):
				methods.append(m.name)
	
	return methods
