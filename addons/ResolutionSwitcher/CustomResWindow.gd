tool
extends WindowDialog

const CUSTOM_LIST_FILE_PATH: String = "res://addons/ResolutionSwitcher/lists/list_custom.txt";

signal reload;

# Config file to load resolution list file:
var config_file: ConfigFile = null;


func _ready():
	config_file = ConfigFile.new();

func _on_ok_pressed():
	config_file.load(CUSTOM_LIST_FILE_PATH)
	var width: String = String(find_node("width").text);
	var height: String = String(find_node("height").text);
	var label: String = String(find_node("labelv").text);

	var text : String = width + "x" + height;

	config_file.set_value("Custom Resolutions", label, text);
	config_file.save(CUSTOM_LIST_FILE_PATH);
	emit_signal("reload");
	
	hide();


func _on_cancel_pressed():
	hide();
