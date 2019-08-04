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
var stretch_settings_submenu: PopupMenu = null;
var game_res_submenu: PopupMenu = null;
var set_res_window = null
var custom_res_window = null


# Initialization of the plugin:
func _enter_tree() -> void:
	# Create new menu button:
	toolbar_menu_btn = MenuButton.new();
	toolbar_menu_btn.text = "Resolution";
	toolbar_menu_btn.icon = preload("res://addons/ResolutionSwitcher/iconfinder_desktop_3688496.png");
	
	# Connect id_pressed signal to switch resloution:
	toolbar_menu_popup = toolbar_menu_btn.get_popup();
	toolbar_menu_popup.connect("id_pressed", self, "_on_toolbar_menu_popup_id_pressed");
	
	set_res_window = preload("set_res_window.tscn").instance();
	custom_res_window = preload("custom_res_window.tscn").instance();
	
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
	load_stretch_settings_submenu();
	
	toolbar_menu_popup.add_item("Set Base Resolution");
	toolbar_menu_popup.add_item("Add Custom Resolution");
	toolbar_menu_popup.add_separator();
	toolbar_menu_popup.add_item("Test Resolutions:");
	toolbar_menu_popup.set_item_disabled(4, true);
	
	var node = set_res_window.find_node("OptionButton");
	node.connect("item_selected", self, "_on_node_item_selected");
	
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

func _on_node_item_selected(id: int):
	var key = set_res_window.find_node("OptionButton").get_item_text(id);
	
	var width: int = resolution_data[key]["width"];
	var height: int = resolution_data[key]["height"];
	
	set_res_window.find_node("width").text = String(width);
	set_res_window.find_node("height").text = String(height);


# Create stretch settings submenu:
func load_stretch_settings_submenu() -> void:
	stretch_settings_submenu = PopupMenu.new();
	stretch_settings_submenu.name = "stretch_settings"; # used in add_submenu_item function
	stretch_settings_submenu.connect("id_pressed", self, "_on_stretch_settings_submenu_id_pressed");
	
	stretch_settings_submenu.add_radio_check_item("Full Control: disable, ignored", 0);
	var tip: String = "No stretching happens. One unit in the scene corresponds to one pixel on the screen.\n"
	tip += "Stretch Aspect has no effect. \nGood option for full control over every screen pixel,"
	tip += " best option for 3D games.";
	stretch_settings_submenu.set_item_tooltip(0, tip);
	
	stretch_settings_submenu.add_radio_check_item("Screen Fill: 2d, ignored", 1);
	tip = "Size is stretched to cover the whole screen, Good option for high resolution 2D artwork.\n";
	tip += "Ignore the aspect ratio when stretching the screen.";
	stretch_settings_submenu.set_item_tooltip(1, tip);
	
	stretch_settings_submenu.add_radio_check_item("One Ratio: 2d, keep", 2);
	tip = "Size is stretched to cover the whole screen, Good option for high resolution 2D artwork.\n";
	tip += "Viewport will retains its original size regardless of the screen resolution, \nblack bars will be added to the top/bottom of the screen (“letterboxing”) \nor the sides (“pillarboxing”).";
	tip += " Good option if you know the aspect ratio of your target \ndevices in advance, or if you don’t want to handle different aspect ratios.";
	stretch_settings_submenu.set_item_tooltip(2, tip);
	
	stretch_settings_submenu.add_radio_check_item("GUI/Vertical: 2d, keep_width", 3);
	tip = "Size is stretched to cover the whole screen, Good option for high resolution 2D artwork.\n";
	tip += "If the screen is wider than the base size, black bars are added at the left/right (pillarboxing).\nBut if the screen is taller than the base resolution, the viewport will be grown in the \nvertical direction (and more content will be visible to the bottom). \nYou can also think of this as “Expand Vertically.";
	tip += " Best option for creating GUIs \nor HUDs that scale, so some controls can be anchored to the bottom.";
	stretch_settings_submenu.set_item_tooltip(3, tip);
	
	stretch_settings_submenu.add_radio_check_item("Horizontal platformer: 2d, keep_height", 4);
	tip = "Size is stretched to cover the whole screen, Good option for high resolution 2D artwork.\n";
	tip += "If the screen is taller than the base size, black bars are added at the top/bottom (letterboxing). \nBut if the screen is wider than the base resolution, the viewport will be grown in the \nhorizontal direction (and more content will be visible to the right). \nYou can also think of this as “Expand Horizontally”.";
	tip += " This is usually the best option \nfor 2D games that scroll horizontally (like runners or platformers).";
	stretch_settings_submenu.set_item_tooltip(4, tip);
	
	stretch_settings_submenu.add_radio_check_item("Expand: 2d, expand", 5);
	tip = "Size is stretched to cover the whole screen, Good option for high resolution 2D artwork.\n";
	tip += "Depending on the screen aspect ratio, the viewport will either be larger in the \nhorizontal direction (if the screen is wider than the base size) or in the vertical direction (if the \nscreen is taller than the original size)";
	stretch_settings_submenu.set_item_tooltip(5, tip);
	
	stretch_settings_submenu.add_radio_check_item("Pixel-Perfect, Screen Fill: viewport, ignored", 6);
	tip = "Scene is rendered to viewport, then viewport is scaled to fit the screen. Useful with \npixel-precise games, or rendering to a lower resolution to improve performance.\n";
	tip += "Ignore the aspect ratio when stretching the screen.";
	stretch_settings_submenu.set_item_tooltip(6, tip);
	
	stretch_settings_submenu.add_radio_check_item("Pixel-Perfect, One Ratio: viewport, keep", 7);
	tip = "Scene is rendered to viewport, then viewport is scaled to fit the screen. Useful with \npixel-precise games, or rendering to a lower resolution to improve performance.\n";
	tip += "Viewport will retains its original size regardless of the screen resolution, \nblack bars will be added to the top/bottom of the screen (“letterboxing”) \nor the sides (“pillarboxing”).";
	tip += " Good option if you know the aspect ratio of your target \ndevices in advance, or if you don’t want to handle different aspect ratios.";
	stretch_settings_submenu.set_item_tooltip(7, tip);
	
	stretch_settings_submenu.add_radio_check_item("Pixel-Perfect, GUI/Vertical: viewport, keep_width", 8);
	tip = "Scene is rendered to viewport, then viewport is scaled to fit the screen. Useful with \npixel-precise games, or rendering to a lower resolution to improve performance.\n";
	tip += "If the screen is wider than the base size, black bars are added at the left/right (pillarboxing).\nBut if the screen is taller than the base resolution, the viewport will be grown in the \nvertical direction (and more content will be visible to the bottom). \nYou can also think of this as “Expand Vertically.";
	tip += " Best option for creating GUIs \nor HUDs that scale, so some controls can be anchored to the bottom.";
	stretch_settings_submenu.set_item_tooltip(8, tip);
	
	stretch_settings_submenu.add_radio_check_item("Pixel-Perfect, Horizontal platformer: viewport, keep_height", 9);
	tip = "Scene is rendered to viewport, then viewport is scaled to fit the screen. Useful with \npixel-precise games, or rendering to a lower resolution to improve performance.\n";
	tip += "If the screen is taller than the base size, black bars are added at the top/bottom (letterboxing). \nBut if the screen is wider than the base resolution, the viewport will be grown in the \nhorizontal direction (and more content will be visible to the right). \nYou can also think of this as “Expand Horizontally”.";
	tip += " This is usually the best option \nfor 2D games that scroll horizontally (like runners or platformers).";
	stretch_settings_submenu.set_item_tooltip(9, tip);
	
	stretch_settings_submenu.add_radio_check_item("Pixel-Perfect, Expand: viewport, expand", 10);
	tip = "Scene is rendered to viewport, then viewport is scaled to fit the screen. Useful with \npixel-precise games, or rendering to a lower resolution to improve performance.\n";
	tip += "Depending on the screen aspect ratio, the viewport will either be larger in the \nhorizontal direction (if the screen is wider than the base size) or in the vertical direction\n(if the screen is taller than the original size)";
	stretch_settings_submenu.set_item_tooltip(10, tip);
	
	update_radio_group_check_state(stretch_settings_submenu, 0);
	
	toolbar_menu_popup.add_child(stretch_settings_submenu);
	toolbar_menu_popup.add_submenu_item("Stretch Settings", "stretch_settings");


func _on_stretch_settings_submenu_id_pressed(id: int) -> void:
	if id == 0:
		update_radio_group_check_state(stretch_settings_submenu, 0);
		ProjectSettings.set_setting("display/window/stretch/mode", "disabled");
		ProjectSettings.set_setting("display/window/stretch/aspect", "ignore");
	elif id == 1:
		update_radio_group_check_state(stretch_settings_submenu, 1);
		ProjectSettings.set_setting("display/window/stretch/mode", "2d");
		ProjectSettings.set_setting("display/window/stretch/aspect", "ignore");
	elif id == 2:
		update_radio_group_check_state(stretch_settings_submenu, 2);
		ProjectSettings.set_setting("display/window/stretch/mode", "2d");
		ProjectSettings.set_setting("display/window/stretch/aspect", "keep");
	elif id == 3:
		update_radio_group_check_state(stretch_settings_submenu, 3);
		ProjectSettings.set_setting("display/window/stretch/mode", "2d");
		ProjectSettings.set_setting("display/window/stretch/aspect", "keep_width");
	elif id == 4:
		update_radio_group_check_state(stretch_settings_submenu, 4);
		ProjectSettings.set_setting("display/window/stretch/mode", "2d");
		ProjectSettings.set_setting("display/window/stretch/aspect", "keep_height");
	elif id == 5:
		update_radio_group_check_state(stretch_settings_submenu, 5);
		ProjectSettings.set_setting("display/window/stretch/mode", "2d");
		ProjectSettings.set_setting("display/window/stretch/aspect", "expand");
	elif id == 6:
		update_radio_group_check_state(stretch_settings_submenu, 6);
		ProjectSettings.set_setting("display/window/stretch/mode", "viewport");
		ProjectSettings.set_setting("display/window/stretch/aspect", "ignore");
	elif id == 7:
		update_radio_group_check_state(stretch_settings_submenu, 7);
		ProjectSettings.set_setting("display/window/stretch/mode", "viewport");
		ProjectSettings.set_setting("display/window/stretch/aspect", "keep");
	elif id == 8:
		update_radio_group_check_state(stretch_settings_submenu, 8);
		ProjectSettings.set_setting("display/window/stretch/mode", "viewport");
		ProjectSettings.set_setting("display/window/stretch/aspect", "keep_width");
	elif id == 9:
		update_radio_group_check_state(stretch_settings_submenu, 9);
		ProjectSettings.set_setting("display/window/stretch/mode", "viewport");
		ProjectSettings.set_setting("display/window/stretch/aspect", "keep_height");
	elif id == 10:
		update_radio_group_check_state(stretch_settings_submenu, 10);
		ProjectSettings.set_setting("display/window/stretch/mode", "viewport");
		ProjectSettings.set_setting("display/window/stretch/aspect", "expand");
	else:
		return;


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
		
	custom_res_window.show();
	custom_res_window.popup_centered();
	custom_res_window.find_node("ok").connect("pressed", self, "_on_ok2", [], CONNECT_ONESHOT);
	custom_res_window.find_node("cancel").connect("pressed", self, "_on_cancel2", [], CONNECT_ONESHOT);


func set_res_logic() -> void:
	if set_res_window.get_parent() == null:
		add_child(set_res_window);
	
	set_res_window.find_node("width").text = String(ProjectSettings.get_setting("display/window/size/width"));
	set_res_window.find_node("height").text = String(ProjectSettings.get_setting("display/window/size/height"));
	set_res_window.find_node("current").text = "    Current resolution: " + set_res_window.find_node("width").text + " x " + set_res_window.find_node("height").text;

	set_res_window.show();
	set_res_window.popup_centered();
	set_res_window.find_node("ok").connect("pressed", self, "_on_ok", [], CONNECT_ONESHOT);
	set_res_window.find_node("cancel").connect("pressed", self, "_on_cancel", [], CONNECT_ONESHOT);

func _on_ok():
	var width: int = int(set_res_window.find_node("width").text);
	var height: int = int(set_res_window.find_node("height").text);
	ProjectSettings.set_setting("display/window/size/width", width);
	ProjectSettings.set_setting("display/window/size/height", height);
	ProjectSettings.save();
	set_res_window.hide();

func _on_ok2():
	var width: String = String(custom_res_window.find_node("width").text);
	var height: String = String(custom_res_window.find_node("height").text);
	var label: String = String(custom_res_window.find_node("labelv").text);
	
	var text : String = width + "x" + height;
	
	config_file.set_value("Old Resolutions", label, text);
	config_file.save(RESOLUTION_LIST_FILE_PATH);
	load_resolution_list();
		
	custom_res_window.hide();

func _on_cancel():
	set_res_window.hide();

func _on_cancel2():
	custom_res_window.hide();

func get_plugin_name() -> String: 
	return "ResolutionSwitcher";


func _init() -> void:
	pass












