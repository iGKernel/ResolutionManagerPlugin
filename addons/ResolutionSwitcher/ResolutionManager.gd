tool
extends EditorPlugin

# Text file contain list of pre-defined resolutions:
const RESOLUTION_LIST_FILE_PATH: String = "res://addons/ResolutionSwitcher/lists/list.txt";
const LARGE_LIST_FILE_PATH: String = "res://addons/ResolutionSwitcher/lists/list_large.txt";
const IPHONE_LIST_FILE_PATH: String = "res://addons/ResolutionSwitcher/lists/list_iphone.txt";
const MOSTUSED_LIST_FILE_PATH: String = "res://addons/ResolutionSwitcher/lists/list_mostused.txt";
const CUSTOM_LIST_FILE_PATH: String = "res://addons/ResolutionSwitcher/lists/list_custom.txt";

var json_dict = {}
var res_list_id = 0;

var current_list: String = RESOLUTION_LIST_FILE_PATH;

# Config file to load resolution list file:
var config_file: ConfigFile = null;

# Dictionary to hold the width and height of clicked resolution:
var resolution_data: Dictionary = {};

# Canvas editor menu button and popup:
var toolbar_menu_btn: MenuButton = null;
var toolbar_menu_popup: PopupMenu  = null;
var stretch_settings_submenu: PopupMenu = null;
var list_submenu: PopupMenu = null;
var game_res_submenu: PopupMenu = null;
var set_res_window = null
var custom_res_window = null
var first: bool = true;
var last_list = 0;
var last_stretch = 0;

# Initialization of the plugin:
func _enter_tree() -> void:
	var file = File.new()
	file.open("res://addons/ResolutionSwitcher/stretch_settings_tooltip.json", file.READ)
	var text = file.get_as_text()
	json_dict = parse_json(text)
	#print(json_dict["stretch"]["0"])
	file.close()

	# Create new menu button:
	toolbar_menu_btn = MenuButton.new();
	toolbar_menu_btn.text = "Resolution";
	toolbar_menu_btn.icon = preload("res://addons/ResolutionSwitcher/icons/iconfinder_desktop_3688496.png");
	
	# Connect id_pressed signal to switch resloution:
	toolbar_menu_popup = toolbar_menu_btn.get_popup();
	toolbar_menu_popup.connect("id_pressed", self, "_on_toolbar_menu_popup_id_pressed");
	
	set_res_window = preload("set_res_window.tscn").instance();
	custom_res_window = preload("CustomResWindow.tscn").instance();
	add_child(custom_res_window);
	
	# Fill popup menu and resolution data dictionary:
	load_resolution_list();
	
	# Add menu button to canvas editor toolbar:
	add_control_to_container(CONTAINER_CANVAS_EDITOR_MENU, toolbar_menu_btn);


# Clean-up of the plugin:
func _exit_tree() -> void:
	# Remove menu button from canvas editor toolbar:
	remove_control_from_container(CONTAINER_CANVAS_EDITOR_MENU, toolbar_menu_btn);
	
	# Clear popup menu and resolution data dictionary:
	resolution_data.clear();
	toolbar_menu_popup.clear();
	
	# Disconnect id_pressed signal:
	toolbar_menu_popup.disconnect("id_pressed", self, "_on_toolbar_menu_popup_id_pressed");
	
	# Free menu button and popup:
	toolbar_menu_popup.queue_free();
	toolbar_menu_btn.queue_free();


# Fill popup menu and resolution data dictionary:
func load_resolution_list() -> void:
	# Load resolution list:
	
	#if not config_file:
	config_file = ConfigFile.new();
	var is_loaded: = config_file.load(current_list);
	if is_loaded != OK:
		return;
	
	resolution_data = {};
	toolbar_menu_popup.clear();

	#toolbar_menu_popup.remove_child(stretch_settings_submenu);
	#toolbar_menu_popup.remove_child(list_submenu);
	
	# Load submenus:
	#if first:
	load_stretch_settings_submenu();
	load_list_submenu();
	

	toolbar_menu_popup.add_item("Set Base Resolution");
	toolbar_menu_popup.add_item("Add Custom Resolution");
	toolbar_menu_popup.add_separator();
	toolbar_menu_popup.add_item("Test Resolutions:");
	toolbar_menu_popup.set_item_disabled(5, true);
	if res_list_id == 4:
		toolbar_menu_popup.set_item_disabled(3, false);
	else:
		toolbar_menu_popup.set_item_disabled(3, true);
		
	#	first = false;
	#else:
	#	for i in range(6, toolbar_menu_popup.get_item_count()):
	#		toolbar_menu_popup.remove_item(i);
	
	var node = set_res_window.find_node("OptionButton");
	if first:
		node.connect("item_selected", self, "_on_node_item_selected");
		first = false;
	node.clear();
	
	# Fill data:
	var sections: PoolStringArray = config_file.get_sections();
	
	for section in sections:
		var keys: PoolStringArray = config_file.get_section_keys(section);
		toolbar_menu_popup.add_separator(section);
		node.add_separator();
		
		for key in keys:
			# Split at "x":
			var value = config_file.get_value(section,key).split("x");
			var width = value[0];
			var height = value[1];
			var text = key + "    (" + width + "x" + height +")";
			
			resolution_data[text] = {
				"label": key,
				"width": width,
				"height": height
			};
			
			toolbar_menu_popup.add_item(text);
			node.add_item(text);


func _on_node_item_selected(id: int) -> void:
	var key = set_res_window.find_node("OptionButton").get_item_text(id);
#	var idx = set_res_window.find_node("OptionButton").get_item_index(id);
#	set_res_window.find_node("OptionButton").select(idx);
	
	var width: int = resolution_data[key]["width"];
	var height: int = resolution_data[key]["height"];
	
	set_res_window.find_node("width").text = String(width);
	set_res_window.find_node("height").text = String(height);


func load_list_submenu() -> void:
	if list_submenu:
		toolbar_menu_popup.remove_child(list_submenu);
		list_submenu.clear();
		list_submenu.queue_free();
	
	list_submenu = PopupMenu.new();
	list_submenu.name = "list"; # used in add_submenu_item function
	list_submenu.connect("id_pressed", self, "_on_list_submenu_id_pressed");

	list_submenu.add_radio_check_item("Basic List", 0);
	list_submenu.add_radio_check_item("Large List", 1);
	list_submenu.add_radio_check_item("IPhone List", 2);
	list_submenu.add_radio_check_item("Most Used List", 3);
	list_submenu.add_radio_check_item("Custom List", 4);

	update_radio_group_check_state(list_submenu, last_list);
	
	toolbar_menu_popup.add_child(list_submenu);
	toolbar_menu_popup.add_submenu_item("Resolution List", "list");


# Create stretch settings submenu:
func load_stretch_settings_submenu() -> void:
	if stretch_settings_submenu:
		toolbar_menu_popup.remove_child(stretch_settings_submenu);
		stretch_settings_submenu.clear();
		stretch_settings_submenu.queue_free();
		
	stretch_settings_submenu = PopupMenu.new();
	stretch_settings_submenu.name = "stretch_settings"; # used in add_submenu_item function
	stretch_settings_submenu.connect("id_pressed", self, "_on_stretch_settings_submenu_id_pressed");
	
	var array: Array =["Screen Fill: 2d, ignored", "One Ratio: 2d, keep",
	"GUI/Vertical: 2d, keep_width", "Horizontal platformer: 2d, keep_height", "Expand: 2d, expand"];
	
	var text: String = "Full Control: disable, ignored";
	for i in range(11):
		if i != 0 and i < 6:
			text = array[i-1]
		elif i >= 6:
			text = "Pixel-Perfect, " + array[fmod(i-1, 5)];
		
		stretch_settings_submenu.add_radio_check_item(text, i);
		stretch_settings_submenu.set_item_tooltip(i, json_dict[String(i)]);
	
	update_radio_group_check_state(stretch_settings_submenu, last_stretch);
	
	toolbar_menu_popup.add_child(stretch_settings_submenu);
	toolbar_menu_popup.add_submenu_item("Stretch Settings", "stretch_settings");


func _on_list_submenu_id_pressed(id: int) -> void:
	var idx = list_submenu.get_item_index(id);
	update_radio_group_check_state(list_submenu, idx);
	res_list_id = idx;
	if idx == 0:
		current_list = RESOLUTION_LIST_FILE_PATH;
	elif idx == 1:
		current_list = LARGE_LIST_FILE_PATH;
	elif idx == 2:
		current_list = IPHONE_LIST_FILE_PATH;
	elif idx == 3:
		current_list = MOSTUSED_LIST_FILE_PATH;
	elif idx == 4:
		current_list = CUSTOM_LIST_FILE_PATH;
	
	last_list = idx;
	load_resolution_list();


func _on_stretch_settings_submenu_id_pressed(id: int) -> void:
	var array: Array = ["ignore", "keep", "keep_width", "keep_height", "expand"];
	var mode = "disabled";
	var aspect = "ignore";
	if id != 0 and id < 6:
		mode = "2d";
		aspect = array[id-1];
	elif id >= 6:
		mode = "viewport";
		aspect = array[fmod(id-1, 5)];

	update_radio_group_check_state(stretch_settings_submenu, id);
	ProjectSettings.set_setting("display/window/stretch/mode", mode);
	ProjectSettings.set_setting("display/window/stretch/aspect", aspect);
	last_stretch = id;


func update_radio_group_check_state(menu: PopupMenu, idx: int) -> void:
	var item_count: int = menu.get_item_count();
	for i in range(item_count):
		if i == idx:
			if not menu.is_item_checked(i):
				menu.toggle_item_checked(i);
		else:
			if menu.is_item_checked(i):
				menu.toggle_item_checked(i);


func _on_toolbar_menu_popup_id_pressed(id: int) -> void:
	var key := toolbar_menu_popup.get_item_text(id);
	if key == "Set Base Resolution":
		set_res_logic();
	elif key == "Add Custom Resolution":
		custom_res_logic();
	else:
		var width: int = resolution_data[key]["width"];
		var height: int = resolution_data[key]["height"];
		
		toolbar_menu_btn.set_text(key);
		
		ProjectSettings.set_setting("display/window/size/test_width", width);
		ProjectSettings.set_setting("display/window/size/test_height", height);
		ProjectSettings.save();


func custom_res_logic() -> void:
	if custom_res_window.get_parent() == null:
		add_child(custom_res_window);
	
	custom_res_window.connect("reload", self, "load_resolution_list");	
	custom_res_window.show();
	custom_res_window.popup_centered();
	custom_res_window.find_node("ok").connect("pressed", self, "_on_ok2", [], CONNECT_ONESHOT);
	custom_res_window.find_node("cancel").connect("pressed", self, "_on_cancel2", [], CONNECT_ONESHOT);


func set_res_logic() -> void:
	if set_res_window.get_parent() == null:
		add_child(set_res_window);
	
	set_res_window.find_node("OptionButton").text = "Choose pre-defined resolution";
	set_res_window.find_node("width").text = "";
	set_res_window.find_node("height").text = "";
	set_res_window.find_node("width").placeholder_text = "Enter Width";
	set_res_window.find_node("height").placeholder_text = "Enter Height";
	var current_size: Vector2 = Vector2();
	current_size.x = ProjectSettings.get_setting("display/window/size/width");
	current_size.y = ProjectSettings.get_setting("display/window/size/height");
	set_res_window.find_node("current").text = "    Current resolution: " + String(current_size.x) + " x " + String(current_size.y);

	set_res_window.show();
	set_res_window.popup_centered();
	set_res_window.find_node("ok").connect("pressed", self, "_on_ok", [], CONNECT_ONESHOT);
	set_res_window.find_node("cancel").connect("pressed", self, "_on_cancel", [], CONNECT_ONESHOT);


func _on_ok() -> void:
	var width: int = int(set_res_window.find_node("width").text);
	var height: int = int(set_res_window.find_node("height").text);
	ProjectSettings.set_setting("display/window/size/width", width);
	ProjectSettings.set_setting("display/window/size/height", height);
	ProjectSettings.save();
	set_res_window.hide();


func _on_ok2() -> void:
	var width: String = String(custom_res_window.find_node("width").text);
	var height: String = String(custom_res_window.find_node("height").text);
	var label: String = String(custom_res_window.find_node("labelv").text);

	var text : String = width + "x" + height;

	config_file.set_value("Custom Resolutions", label, text);
	config_file.save(CUSTOM_LIST_FILE_PATH);
	load_resolution_list();

	custom_res_window.hide();


func _on_cancel() -> void:
	set_res_window.hide();


func _on_cancel2() -> void:
	custom_res_window.hide();


func get_plugin_name() -> String: 
	return "ResolutionSwitcher";


func _init() -> void:
	pass












