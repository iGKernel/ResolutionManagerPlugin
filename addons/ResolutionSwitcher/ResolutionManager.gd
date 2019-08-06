tool
extends EditorPlugin

# Canvas editor menu button and popup:
var toolbar_menu_btn: MenuButton = null;

# Initialization of the plugin:
func _enter_tree()-> void:
	# Instance menu button:
	toolbar_menu_btn = preload("ResolutionButton.tscn").instance();
	
	# Add menu button to canvas editor toolbar:
	add_control_to_container(CONTAINER_CANVAS_EDITOR_MENU, toolbar_menu_btn);


# Clean-up of the plugin:
func _exit_tree()-> void:
	# Remove menu button from canvas editor toolbar:
	remove_control_from_container(CONTAINER_CANVAS_EDITOR_MENU, toolbar_menu_btn);
	
	# Free menu button:
	toolbar_menu_btn.queue_free();

func get_plugin_name()-> String: 
	return "ResolutionManager";