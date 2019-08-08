tool
extends MenuButton

# Text file contain list of pre-defined resolutions:
const RESOLUTION_LIST_FILE_PATH: String = "res://addons/ResolutionSwitcher/lists/list.txt";
const LARGE_LIST_FILE_PATH: String = "res://addons/ResolutionSwitcher/lists/list_large.txt";
const IPHONE_LIST_FILE_PATH: String = "res://addons/ResolutionSwitcher/lists/list_iphone.txt";
const MOSTUSED_LIST_FILE_PATH: String = "res://addons/ResolutionSwitcher/lists/list_mostused.txt";
const CUSTOM_LIST_FILE_PATH: String = "res://addons/ResolutionSwitcher/lists/list_custom.txt";
const TOOLTIP_JSON_FILE_PATH: String = "res://addons/ResolutionSwitcher/stretch_settings_tooltip.json";

# Canvas editor menu button and popup:
var menu_popup: PopupMenu = null;
var stretch_settings_submenu: PopupMenu = null;
var list_submenu: PopupMenu = null;
var set_res_window: Node = null;
var custom_res_window: Node = null;

var config_file: ConfigFile = null;
var resolution_data: Dictionary = {};
var json_dict: Dictionary = {};
var current_list: String = RESOLUTION_LIST_FILE_PATH;
var res_list_id: int = 0;
var last_list: int = 0;
var last_stretch: int = 0;

func _enter_tree()-> void:
	# Init Set base resolution window:
	set_res_window = preload("BaseResWindow.tscn").instance();
	add_child(set_res_window);
	
	# Init custom resolution window:
	custom_res_window = preload("CustomResWindow.tscn").instance();
	custom_res_window.connect("reload", self, "load_resolution_list")
	add_child(custom_res_window);
	
	# Parse JSON file:
	var file: File = File.new();
	file.open(TOOLTIP_JSON_FILE_PATH, file.READ);
	json_dict = parse_json(file.get_as_text());
	file.close();
	
	# Connect index_pressed signal to switch resloution:
	menu_popup = get_popup();
	menu_popup.connect("index_pressed", self, "_on_menu_popup_index_pressed");
	
	# Fill popup menu and resolution data dictionary:
	load_resolution_list();


func _exit_tree()-> void:
	# Clear popup menu and resolution data dictionary:
	resolution_data.clear();
	json_dict.clear();
	menu_popup.clear();
	
	# Free menu button and popup:
	menu_popup.queue_free();
	stretch_settings_submenu.queue_free();
	list_submenu.queue_free();
	set_res_window.queue_free();
	custom_res_window.queue_free();


# Fill popup menu and resolution data dictionary:
func load_resolution_list()-> void:
	config_file = ConfigFile.new();
	var is_loaded: = config_file.load(current_list);
	if is_loaded != OK:
		return;
	
	resolution_data = {};
	menu_popup.clear();

	load_stretch_settings_submenu();
	load_list_submenu();
	
	menu_popup.add_item("Set Base Resolution");
	menu_popup.add_item("Add Custom Resolution");
	menu_popup.add_separator();
	menu_popup.add_item("Test Resolutions:");
	menu_popup.set_item_disabled(5, true);
	
	if res_list_id == 4:
		menu_popup.set_item_disabled(3, false);
	else:
		menu_popup.set_item_disabled(3, true);
	
	var node = set_res_window.find_node("OptionButton");
	node.clear();
	
	# Fill data:
	for section in config_file.get_sections():
		menu_popup.add_separator(section);
		
		for key in config_file.get_section_keys(section):
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
			
			menu_popup.add_item(text);
			node.add_item(text);
			
		node.add_separator();


# Create stretch settings submenu:
func load_stretch_settings_submenu()-> void:
	var load_last: bool = true;
	if stretch_settings_submenu:
		menu_popup.remove_child(stretch_settings_submenu);
		stretch_settings_submenu.clear();
		stretch_settings_submenu.queue_free();
		load_last = false;
		
	stretch_settings_submenu = PopupMenu.new();
	stretch_settings_submenu.name = "stretch_settings";
	stretch_settings_submenu.connect("index_pressed", self, 
				"_on_stretch_settings_submenu_index_pressed");
	
	var array: Array =["Screen Fill: 2d, ignored", "One Ratio: 2d, keep",
	"GUI/Vertical: 2d, keep_width", "Horizontal platformer: 2d, keep_height", "Expand: 2d, expand"];
	
	var text: String = "Full Control: disable, ignored";
	for i in range(11):
		if i != 0 and i < 6:
			text = array[i-1];
		elif i >= 6:
			text = "Pixel-Perfect, " + array[fmod(i-1, 5)];
		
		stretch_settings_submenu.add_radio_check_item(text, i);
		stretch_settings_submenu.set_item_tooltip(i, json_dict[String(i)]);
	
	if load_last:
		var mode = String(ProjectSettings.get_setting("display/window/stretch/mode"));
		var aspect = String(ProjectSettings.get_setting("display/window/stretch/aspect"));
		var aspects: Array = ["ignore", "keep", "keep_width", "keep_height", "expand"];
		if mode == "disabled":
			last_stretch = 0;
		elif mode == "2d":
			last_stretch = aspects.find(aspect) + 1;
		elif mode == "viewport":
			last_stretch = aspects.find(aspect) + 6;
		
	update_radio_group_check_state(stretch_settings_submenu, last_stretch);
	
	menu_popup.add_child(stretch_settings_submenu);
	menu_popup.add_submenu_item("Stretch Settings", "stretch_settings");


func load_list_submenu()-> void:
	if list_submenu:
		menu_popup.remove_child(list_submenu);
		list_submenu.clear();
		list_submenu.queue_free();
	
	list_submenu = PopupMenu.new();
	list_submenu.name = "list_submenu"; # used in add_submenu_item function
	list_submenu.connect("id_pressed", self, "_on_list_submenu_id_pressed");

	list_submenu.add_radio_check_item("Basic List", 0);
	list_submenu.add_radio_check_item("Large List", 1);
	list_submenu.add_radio_check_item("IPhone List", 2);
	list_submenu.add_radio_check_item("Most Used List", 3);
	list_submenu.add_radio_check_item("Custom List", 4);

	update_radio_group_check_state(list_submenu, last_list);
	
	menu_popup.add_child(list_submenu);
	menu_popup.add_submenu_item("Resolution List", "list_submenu");


func update_radio_group_check_state(menu: PopupMenu, idx: int)-> void:
	var item_count: int = menu.get_item_count();
	for i in range(item_count):
		if i == idx:
			if not menu.is_item_checked(i):
				menu.toggle_item_checked(i);
		else:
			if menu.is_item_checked(i):
				menu.toggle_item_checked(i);


func _on_menu_popup_index_pressed(idx: int)-> void:
	var key := menu_popup.get_item_text(idx);
	if key == "Set Base Resolution":
		set_res_window.show();
		set_res_window.popup_centered();
	elif key == "Add Custom Resolution":
		custom_res_window.show();
		custom_res_window.popup_centered();
	else:
		var width: int = resolution_data[key]["width"];
		var height: int = resolution_data[key]["height"];
		
		text = key;
		
		ProjectSettings.set_setting("display/window/size/test_width", width);
		ProjectSettings.set_setting("display/window/size/test_height", height);
		ProjectSettings.save();


func _on_stretch_settings_submenu_index_pressed(idx: int)-> void:
	var array: Array = ["ignore", "keep", "keep_width", "keep_height", "expand"];
	var mode = "disabled";
	var aspect = "ignore";
	if idx != 0 and idx < 6:
		mode = "2d";
		aspect = array[idx-1];
	elif idx >= 6:
		mode = "viewport";
		aspect = array[fmod(idx-1, 5)];

	update_radio_group_check_state(stretch_settings_submenu, idx);
	ProjectSettings.set_setting("display/window/stretch/mode", mode);
	ProjectSettings.set_setting("display/window/stretch/aspect", aspect);
	last_stretch = idx;


func _on_list_submenu_id_pressed(id: int)-> void:
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


