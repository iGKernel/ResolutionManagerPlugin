tool
extends EditorPlugin

# Text file contain list of pre-defined resolutions:
const RESOLUTION_LIST_FILE_PATH: String = "res://addons/ResolutionSwitcher/list.txt";

# Config file to load resolution list file:
var config_file: ConfigFile = null;

# Dictionary to hold the width and height of clicked resolution:
var resolution_data: Dictionary = {};

# Canvas editor menu button and popup:
var toolbar_menu_btn: MenuButton = null;
var toolbar_menu_popup: PopupMenu  = null;
var stretch_mode_submenu: PopupMenu = null;
var stretch_aspect_submenu: PopupMenu = null;


# Initialization of the plugin:
func _enter_tree() -> void:
	# Create new menu button:
	toolbar_menu_btn = MenuButton.new();
	toolbar_menu_btn.text = "Switch Resolution";
	
	# Connect id_pressed signal to switch resloution:
	toolbar_menu_popup = toolbar_menu_btn.get_popup();
	toolbar_menu_popup.connect("id_pressed", self, "_on_toolbar_menu_popup_id_pressed");
	
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
	config_file = ConfigFile.new();
	var is_loaded: = config_file.load(RESOLUTION_LIST_FILE_PATH);	
	if is_loaded != OK:
		return;
	
	resolution_data = {};
	toolbar_menu_popup.clear();
	
	# Load submenus:
	load_stretch_mode_submenu();
	load_stretch_aspect_submenu();
	toolbar_menu_popup.add_separator();
	
	# Fill data:
	var sections: PoolStringArray = config_file.get_sections();
	for section in sections:
		var keys: PoolStringArray = config_file.get_section_keys(section);
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
		
		toolbar_menu_popup.add_separator();


# Create stretch mode submenu:
func load_stretch_mode_submenu() -> void:
	stretch_mode_submenu = PopupMenu.new();
	stretch_mode_submenu.name = "stretch_mode"; # used in add_submenu_item function
	stretch_mode_submenu.connect("id_pressed", self, "_on_stretch_mode_submenu_id_pressed");
	
	# Group of radio buttons (disabled, 2d, viewport):
	stretch_mode_submenu.add_radio_check_item("disabled                     ", 0);
	stretch_mode_submenu.add_radio_check_item("2d", 1);
	stretch_mode_submenu.add_radio_check_item("viewport", 2);
	update_radio_group_check_state(stretch_mode_submenu, [1, 0, 0]);
	
	toolbar_menu_popup.add_child(stretch_mode_submenu);
	toolbar_menu_popup.add_submenu_item("Stretch Mode", "stretch_mode");


# Create stretch aspect submenu:
func load_stretch_aspect_submenu() -> void:
	stretch_aspect_submenu = PopupMenu.new();
	stretch_aspect_submenu.name = "stretch_aspect"; # used in add_submenu_item function
	stretch_aspect_submenu.connect("id_pressed", self, "_on_stretch_aspect_submenu_id_pressed");
	
	# Group of radio buttons (ignore, keep, keep_width, keep_height, )expand:
	stretch_aspect_submenu.add_radio_check_item("ignore                       ", 0);
	stretch_aspect_submenu.add_radio_check_item("keep", 1);
	stretch_aspect_submenu.add_radio_check_item("keep_width", 2);
	stretch_aspect_submenu.add_radio_check_item("keep_height", 3);
	stretch_aspect_submenu.add_radio_check_item("expand", 4);
	update_radio_group_check_state(stretch_aspect_submenu, [1, 0, 0, 0, 0]);
	
	toolbar_menu_popup.add_child(stretch_aspect_submenu);
	toolbar_menu_popup.add_submenu_item("Stretch Aspect", "stretch_aspect");


func update_radio_group_check_state(menu: PopupMenu, check_array: Array) -> void:
	var location: int = 0;
	for check_item in check_array:
		if check_item:
			if not menu.is_item_checked(location):
				menu.toggle_item_checked(location);
		else:
			if menu.is_item_checked(location):
				menu.toggle_item_checked(location);
		location += 1;


func _on_stretch_mode_submenu_id_pressed(id: int) -> void:
	if id == 0:
		update_radio_group_check_state(stretch_mode_submenu, [1, 0, 0]);
		ProjectSettings.set_setting("display/window/stretch/mode", "disabled");
		#print(ProjectSettings.get_setting("display/window/stretch/mode"))
	elif id == 1:
		update_radio_group_check_state(stretch_mode_submenu, [0, 1, 0]);
		ProjectSettings.set_setting("display/window/stretch/mode", "2d");
	elif id == 2:
		update_radio_group_check_state(stretch_mode_submenu, [0, 0, 1]);
		ProjectSettings.set_setting("display/window/stretch/mode", "viewport");
	else:
		return;


func _on_stretch_aspect_submenu_id_pressed(id: int) -> void:
	if id == 0:
		update_radio_group_check_state(stretch_aspect_submenu, [1, 0, 0, 0, 0]);
		ProjectSettings.set_setting("display/window/stretch/aspect", "ignore");
		#print(ProjectSettings.get_setting("display/window/stretch/aspect"))
	elif id == 1:
		update_radio_group_check_state(stretch_aspect_submenu, [0, 1, 0, 0, 0]);
		ProjectSettings.set_setting("display/window/stretch/aspect", "keep");
	elif id == 2:
		update_radio_group_check_state(stretch_aspect_submenu, [0, 0, 1, 0, 0]);
		ProjectSettings.set_setting("display/window/stretch/aspect", "keep_width");
	elif id == 3:
		update_radio_group_check_state(stretch_aspect_submenu, [0, 0, 0, 1, 0]);
		ProjectSettings.set_setting("display/window/stretch/aspect", "keep_height");
	elif id == 4:
		update_radio_group_check_state(stretch_aspect_submenu, [0, 0, 0, 0, 1]);
		ProjectSettings.set_setting("display/window/stretch/aspect", "expand");
	else:
		return;


func _on_toolbar_menu_popup_id_pressed(id: int) -> void:
	var key = toolbar_menu_popup.get_item_text(id)
	
	var w = resolution_data[key]["width"]
	var h = resolution_data[key]["height"]

	toolbar_menu_btn.set_text(key)

	ProjectSettings.set_setting("display/window/size/width",w)
	ProjectSettings.set_setting("display/window/size/height",h)
	ProjectSettings.save()


func get_plugin_name() -> String: 
	return "ResolutionSwitcher"


func _init() -> void:
	pass