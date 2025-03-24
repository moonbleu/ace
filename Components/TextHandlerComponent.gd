class_name TextHandler
extends HBoxContainer

signal focus_status_changed(block: Node, status: bool)

@export var block_type: String
@export var capitalize_text: bool
@export var is_formattable: bool
@export var empty_space: Label
@export var topic_number: Label
@export var edit: TextEdit
@export var rich_text: RichTextLabel

var _is_focused: bool = false


func _on_edit_focus_entered() -> void:
	if !_is_focused and get_viewport().gui_get_focus_owner() == edit:
		_is_focused = true
		edit.set_caret_column(edit.text.length())
		edit.show()
		if empty_space:
			empty_space.show()
		rich_text.hide()
		focus_status_changed.emit(self, true)


func _on_edit_focus_exited() -> void:
	_is_focused = false
	set_data({"text": edit.text})
	focus_status_changed.emit(self, false)
	if empty_space:
		empty_space.hide()


func focus_on_edit() -> void:
	edit.grab_focus()


func set_data(new_data: Dictionary) -> void:
	if capitalize_text:
		new_data.text = new_data.text.to_upper()
	rich_text.text = new_data.text
	edit.text = new_data.text
	if !new_data.text:
		edit.show()
		rich_text.hide()
	else:
		rich_text.show()
		edit.hide()


func get_block_data() -> Dictionary:
	return {"type": block_type, "text": edit.text}


func set_topic_number(new_topic_number: int, new_sub_topic_number: int) -> void:
	topic_number.text = str(new_topic_number) + "." + str(new_sub_topic_number)


func add_formatting(prefix: String, suffix: String) -> void:
	if edit.has_selection() && is_formattable:
		get_viewport().set_input_as_handled()
		edit.insert_text_at_caret(prefix + edit.get_selected_text() + suffix)
