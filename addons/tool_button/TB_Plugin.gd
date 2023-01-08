@tool
extends EditorPlugin

var plugin

func _enter_tree():
	plugin = preload("res://addons/tool_button/TB_InspectorPlugin.gd").new(self)
	ProjectSettings.set_setting("show_default_buttons", false)
	add_inspector_plugin(plugin)

func _exit_tree():
	remove_inspector_plugin(plugin)

func rescan_filesystem():
	var fs = get_editor_interface().get_resource_filesystem()
	fs.update_script_classes()
	fs.scan_sources()
	fs.scan()
