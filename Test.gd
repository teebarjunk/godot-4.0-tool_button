@tool
extends Node2D

signal signal_test(x)

func _get_tool_buttons():
	return [
		"simple",
		{call="emit_signal", args=["signal_test", 9]},
		{call="advanced", tint=Color.DEEP_SKY_BLUE, args=[2,3,9]}
	]

func _ready():
	signal_test.connect(_signal_test_func)

func _signal_test_func(x): print("Signal Test Worked! Got %s." % [x])

func simple():
	var x = 10
	var y = 20
	return x + y

func advanced(x=1, y=1, z=1):
	return "%s + %s + %s == %s" % [x, y, z, x+y+z]

func callable():
	return "Hee Haw!"

