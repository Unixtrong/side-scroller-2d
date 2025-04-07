extends Node


enum DeviceType { KEYBOARD, NINTENDO, XBOX, PS, UNKNOWN }


const STICK_DEADZONE := 0.5
const MOUSE_DEADZONE := 16.0


var current_device_id: int = -1
var current_device_type: DeviceType = DeviceType.UNKNOWN


func _ready():
	print("InputManager 准备就绪")


func _input(event: InputEvent) -> void:
	if (
		event is InputEventJoypadButton or 
		(event is InputEventJoypadMotion and abs(event.axis_value) > STICK_DEADZONE)
	):
		var device_id = event.device
		if device_id != current_device_id:
			current_device_id = device_id
			current_device_type = classify_device(Input.get_joy_name(device_id))
			print("检测到手柄输入：设备ID=%d，类型=%s" % [device_id, device_type_name(current_device_type)])
	elif (
		event is InputEventKey or
		event is InputEventMouseButton or
		(event is InputEventMouseMotion and abs(event.velocity.length()) > MOUSE_DEADZONE)
	):
		if current_device_type != DeviceType.KEYBOARD:
			current_device_id = -1
			current_device_type = DeviceType.KEYBOARD
			print("检测到键盘输入：设备ID=%d" % [event.device])


func classify_device(name: String) -> DeviceType:
	print("检测到手柄输入：设备名称=%s" % [name])
	var n = name.to_lower()
	if n.find("nintendo") != -1 or n.find("pro") != -1:
		return DeviceType.NINTENDO
	elif n.find("xbox") != -1 or n.find("xinput") != -1:
		return DeviceType.XBOX
	elif (
		n.find("ps") != -1 or
		n.find("sony") != -1 or
		n.find("dualshock") != -1 or
		n.find("wireless") != -1
	):
		return DeviceType.PS
	else:
		return DeviceType.UNKNOWN


func device_type_name(t: DeviceType) -> String:
	match t:
		DeviceType.KEYBOARD: return "键盘"
		DeviceType.NINTENDO: return "任天堂"
		DeviceType.XBOX: return "XBOX"
		DeviceType.PS: return "PlayStation"
		_: return "未知设备"


func vibrate(weak: float, strong: float, duration: float):
	if current_device_type == DeviceType.KEYBOARD:
		print("当前是键盘，不能震动")
		return
	Input.start_joy_vibration(current_device_id, weak, strong, duration)
	print("震动设备 %d：弱 %.2f，强 %.2f，持续 %.2fs" % [current_device_id, weak, strong, duration])
