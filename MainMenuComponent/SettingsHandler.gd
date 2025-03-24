class_name SettingsHandler
extends PanelContainer


@onready var filter_options_button: OptionButton = $VBoxContainer/PanelContainer/VBoxContainer/HBoxContainer/FilterOptionsButton
@onready var lm_path_label: Label = $VBoxContainer/PanelContainer2/VBoxContainer/HBoxContainer2/HBoxContainer/LMPathLabel
@onready var em_path_label: Label = $VBoxContainer/PanelContainer2/VBoxContainer/HBoxContainer3/HBoxContainer/EMPathLabel
@onready var label_2: Label = $VBoxContainer/PanelContainer2/VBoxContainer/Label2
@onready var lm_file_dialog: FileDialog = $VBoxContainer/PanelContainer2/VBoxContainer/HBoxContainer2/LMFileDialog
@onready var em_file_dialog: FileDialog = $VBoxContainer/PanelContainer2/VBoxContainer/HBoxContainer3/EMFileDialog
@onready var view_scale_slider: HSlider = $VBoxContainer/PanelContainer/VBoxContainer/HBoxContainer4/ViewScaleSlider

var view_scale_value: float = 1.0

func _ready() -> void:
	call_deferred("_initialize_settings")


func _initialize_settings() -> void:
	var settings_data: Dictionary = UserDataHandler.get_data().settings
	var screen_mode_saved: int = settings_data.get_or_add("SCREEN_MODE", 0)
	var lm_path_saved: String = settings_data.get_or_add("LM_PATH", "")
	var em_path_saved: String = settings_data.get_or_add("EM_PATH", "")
	var view_scale_saved: int = settings_data.get_or_add("VIEW_SCALE", 1.0)
	_on_filter_options_button_item_selected(screen_mode_saved)
	filter_options_button.selected = screen_mode_saved
	if FileAccess.file_exists(lm_path_saved) and FileAccess.file_exists(em_path_saved):
		lm_path_label.text = lm_path_saved
		em_path_label.text = em_path_saved
		LLMHandler.start_LLMs(lm_path_saved, em_path_saved)
	else:
		printerr("SettingsHandler._initialize_settings(): Model Files not Found")
	get_window().content_scale_factor = view_scale_saved
	view_scale_slider.value = view_scale_saved
	view_scale_value = view_scale_saved


func _on_filter_options_button_item_selected(index: int) -> void:
	match index:
		0:
			get_tree().get_root().get_node("DarkMode").hide()
			get_tree().get_root().get_node("BlueLightFilter").hide()
		1:
			get_tree().get_root().get_node("DarkMode").show()
			get_tree().get_root().get_node("BlueLightFilter").hide()
		2:
			get_tree().get_root().get_node("DarkMode").hide()
			get_tree().get_root().get_node("BlueLightFilter").show()
	var _e: int = UserDataHandler.save_new_data("SETTING", {"name": "SCREEN_MODE", "value": index})


func _on_lm_file_dialog_file_selected(path: String) -> void:
	if FileAccess.file_exists(path):
		var _e: int = UserDataHandler.save_new_data("SETTING", {"name": "LM_PATH", "value": path})
		lm_path_label.text = path
		label_2.show()


func _on_em_file_dialog_file_selected(path: String) -> void:
	if FileAccess.file_exists(path):
		var _e: int = UserDataHandler.save_new_data("SETTING", {"name": "EM_PATH", "value": path})
		em_path_label.text = path
		label_2.show()


func _on_lm_button_pressed() -> void:
	lm_file_dialog.show()


func _on_em_button_pressed() -> void:
	em_file_dialog.show()


func _on_view_scale_slider_value_changed(value: float) -> void:
	view_scale_value = value


func _on_view_scale_slider_drag_ended(_value_changed: bool) -> void:
	get_window().content_scale_factor = view_scale_value
	var _e: int = UserDataHandler.save_new_data("SETTING", {"name": "VIEW_SCALE", "value": view_scale_value})
