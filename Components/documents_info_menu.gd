class_name DocumentInfoMenu
extends PanelContainer

signal review_pressed(path: String)
signal read_pressed(path: String)
signal edit_pressed(path: String)

@onready var path_label: Label = $VBoxContainer/HBoxContainer2/PathLabel
@onready var title_label: Label = $VBoxContainer/HBoxContainer/TitleLabel
@onready var progress_label: Label = $VBoxContainer/HBoxContainer/ProgressLabel

var path: String

func set_path(new_path: String) -> void:
	await ready
	path = new_path
	path_label.text = new_path


func set_title(new_title: String) -> void:
	await ready
	title_label.text = new_title


func set_progress(new_progress: float) -> void:
	await ready
	progress_label.text = str(int(new_progress * 100)) + "%"


func _on_review_button_pressed() -> void:
	review_pressed.emit(path)


func _on_read_button_pressed() -> void:
	read_pressed.emit(path)


func _on_edit_button_pressed() -> void:
	edit_pressed.emit(path)
