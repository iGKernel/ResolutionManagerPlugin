tool
extends WindowDialog

const CUSTOM_LIST_FILE_PATH: String = "res://addons/ResolutionSwitcher/lists/list_custom.txt";

signal reload;

onready var config_file: ConfigFile = ConfigFile.new();
onready var width_node: LineEdit = find_node("width");
onready var height_node: LineEdit = find_node("height");
onready var label_node: LineEdit = find_node("labelv");


# Save size in config file and reload the menu:
func _on_ok_pressed()-> void:
	var label: String = label_node.text;
	var text : String = width_node.text + "x" + height_node.text;

	config_file.load(CUSTOM_LIST_FILE_PATH);
	config_file.set_value("Custom Resolutions", label, text);
	config_file.save(CUSTOM_LIST_FILE_PATH);
	
	emit_signal("reload");
	
	hide();
	_clear_line_edit_texts();


func _on_cancel_pressed()-> void:
	hide();
	_clear_line_edit_texts();


func _clear_line_edit_texts()-> void:
	width_node.clear();
	height_node.clear();
	label_node.clear();




