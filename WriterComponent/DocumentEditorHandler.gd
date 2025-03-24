class_name DocumentEditorHandler
extends PanelContainer

const CONTENT: PackedScene = preload("res://WriterComponent/DocumentBlocks/content.tscn")
const DESCRIPTION: PackedScene = preload("res://WriterComponent/DocumentBlocks/description.tscn")
const HEADER: PackedScene = preload("res://WriterComponent/DocumentBlocks/header.tscn")
const IMAGE: PackedScene = preload("res://WriterComponent/DocumentBlocks/image.tscn")
const LESSON: PackedScene = preload("res://WriterComponent/DocumentBlocks/lesson.tscn")
const REVIEW_CONTAINER: PackedScene = preload("res://ReviewComponent/review_container.tscn")
const SUB_HEADER: PackedScene = preload("res://WriterComponent/DocumentBlocks/sub_header.tscn")
const TABLE: PackedScene = preload("res://WriterComponent/DocumentBlocks/table.tscn")

@export var lesson_dir: String

var _current_focus_block: Node
var action_map: Dictionary = {
	"ui_accept": func() -> void: _create_new_block(1),
	"ui_delete": func() -> void: _handle_delete(),
	"ui_tab": func() -> void: _handle_tab(1),
	"ui_shift_tab": func() -> void: _handle_tab(-1),
	"ui_control_up": func() -> void: _handle_control_up(),
	"ui_control_down": func() -> void: _handle_control_down(),
	"ui_alt_up": func() -> void: _move_current_block(-1),
	"ui_alt_down": func() -> void: _move_current_block(1),
	"ui_bold": func() -> void: _format_bold(),
	"ui_italic": func() -> void: _format_italics(),
	"ui_underline": func() -> void: _format_underline(),
	"ui_paste": func() -> void: _create_image(),
	"ui_control_left": func() -> void: _handle_control_left(),
	"ui_control_right": func() -> void: _handle_control_right(),
	"ui_control_enter": func() -> void: _handle_control_enter(),
	"ui_alt_enter": func() -> void: _handle_alt_enter(),
	"ui_control_delete": func() -> void: _handle_control_delete(),
	"ui_alt_delete": func() -> void: _handle_alt_delete(),
	"ui_shift_delete": func() -> void: _delete_current_block(),
	"create_table": func() -> void: _create_table(),
}


func _input(_event: InputEvent) -> void:
	if visible:
		if _current_focus_block:
			for action: String in action_map.keys():
				if Input.is_action_just_pressed(action, true):
					action_map[action].call()
					break
		if Input.is_action_just_pressed("ui_save", true):
			get_viewport().set_input_as_handled()
			_save_document()


func _unhandled_input(event: InputEvent) -> void:
	if event is not InputEventMouse and _current_focus_block and visible:
		_current_focus_block.request_ready()
		await _current_focus_block.ready
		%DocumentScroll.ensure_control_visible(_current_focus_block)


func load_document(file_path: String) -> String:
	var document: Document = DocumentHandler.get_document(file_path)
	for block: Dictionary in document.data:
		var block_type: String = block.type
		var new_block: Node = _create_block(_get_block_int(block_type))
		new_block.set_data(block)
		new_block.focus_status_changed.connect(_change_focus_block)
		%DocumentContainer.add_child(new_block)
		print("WriterHandler.load_document(): Loaded Block with Type " + block_type)
	return ""


func _block_navigation(direction: int) -> void:
	var current_index: int = _current_focus_block.get_index()
	var child_count: int = %DocumentContainer.get_child_count()

	var target_index: int
	if direction != 0:
		target_index = current_index + direction
	else:
		if current_index < child_count - 1:
			target_index = current_index + 1
		else:
			target_index = current_index - 1

	if target_index >= 0 and target_index < child_count:
		%DocumentContainer.get_child(target_index).focus_on_edit()


func _create_block(block_int: int, up_to: int = 5) -> Node:
	match clamp(block_int, 0, up_to):
		0:
			return LESSON.instantiate()
		1:
			return HEADER.instantiate()
		2:
			return SUB_HEADER.instantiate()
		3:
			return DESCRIPTION.instantiate()
		4:
			return IMAGE.instantiate()
		5:
			return TABLE.instantiate()
		_:
			return null


func _create_content_label(link_to: Node) -> void:
	var new_content_label: ContentLabel = CONTENT.instantiate()
	var linked_block_data: Dictionary = link_to.get_block_data()
	new_content_label.linked_to = link_to
	match linked_block_data.type:
		"LESSON":
			new_content_label.text = ""
		"HEADER":
			new_content_label.text = "  "
		"SUB_HEADER":
			new_content_label.text = "    "
	new_content_label.text += linked_block_data.text
	%ContentsContainer.add_child(new_content_label)


func _create_new_block(new_block_placement: int) -> void:
	var block_type: String = _current_focus_block.block_type
	var new_block: TextHandler = _create_block(_get_block_int(block_type) + new_block_placement, 3)
	var err: int = new_block.focus_status_changed.connect(_change_focus_block)
	if err:
		printerr("WriterHandler._create_new_block(): Failed to Connect with Err " + str(err))
	%DocumentContainer.add_child(new_block)
	%DocumentContainer.move_child(new_block, _current_focus_block.get_index() + 1)
	_block_navigation(1)


func _create_image() -> void:
	if DisplayServer.clipboard_has_image():
		var image: Image = DisplayServer.clipboard_get_image()
		var image_block: ImageHandler = _create_block(4)
		var err: int = image_block.focus_status_changed.connect(_change_focus_block)
		if err:
			printerr("WriterHandler.create_image(): Failed to Connect with Err " + str(err))
		image_block.set_data({"image": image, "compressed": false})
		%DocumentContainer.add_child(image_block)
		%DocumentContainer.move_child(image_block, _current_focus_block.get_index() + 1)
		_block_navigation(1)


func _create_table() -> void:
	get_viewport().set_input_as_handled()
	var table: TableHandler = _create_block(5)
	var err: int = table.focus_status_changed.connect(_change_focus_block)
	if err:
		printerr("WriterHandler._create_table(): Failed to Connect with Err " + str(err))
	table.set_data({"columns": 1, "cells_data": [""]})
	%DocumentContainer.add_child(table)
	%DocumentContainer.move_child(table, _current_focus_block.get_index() + 1)
	_block_navigation(1)


func _change_focus_block(block: Node, status: bool) -> void:
	if status == true:
		if not block.is_inside_tree():
			block.request_ready()
			await block.ready
		%DocumentScroll.ensure_control_visible(block)
		_current_focus_block = block
	elif _current_focus_block == block:
		_current_focus_block = null


func _delete_current_block() -> void:
	_current_focus_block.queue_free()
	_block_navigation(0)


func _format_bold() -> void:
	_format_current_block_text("[b]", "[/b]")


func _format_current_block_text(prefix: String, suffix: String) -> void:
	if _current_focus_block:
		_current_focus_block.add_formatting(prefix, suffix)


func _format_italics() -> void:
	_format_current_block_text("[i]", "[/i]")


func _format_underline() -> void:
	_format_current_block_text("[u]", "[/u]")


func _get_block_int(block_type_string: String) -> int:
	match block_type_string:
		"LESSON":
			return 0
		"HEADER":
			return 1
		"SUB_HEADER":
			return 2
		"DESCRIPTION":
			return 3
		"IMAGE":
			return 4
		"TABLE":
			return 5
		_:
			return -1


func _handle_alt_delete() -> void:
	if _current_focus_block is TableHandler:
		get_viewport().set_input_as_handled()
		var has_cells: bool = _current_focus_block.delete_column()
		if has_cells == false:
			_delete_current_block()
	else:
		_delete_current_block()


func _handle_alt_enter() -> void:
	if _current_focus_block is TableHandler:
		get_viewport().set_input_as_handled()
		_current_focus_block.add_column()
	else:
		_create_new_block(1)


func _handle_control_delete() -> void:
	if _current_focus_block is TableHandler:
		get_viewport().set_input_as_handled()
		var has_cells: bool = _current_focus_block.delete_row()
		if has_cells == false:
			_delete_current_block()
	else:
		_delete_current_block()


func _handle_control_down() -> void:
	if _current_focus_block is TableHandler:
		get_viewport().set_input_as_handled()
		var is_focused_changed: bool = _current_focus_block.focus_down()
		if not is_focused_changed:
			_block_navigation(1)
	else:
		_block_navigation(1)


func _handle_control_left() -> void:
	if _current_focus_block is TableHandler:
		get_viewport().set_input_as_handled()
		_current_focus_block.focus_left()


func _handle_control_right() -> void:
	if _current_focus_block is TableHandler:
		get_viewport().set_input_as_handled()
		_current_focus_block.focus_right()


func _handle_control_up() -> void:
	if _current_focus_block is TableHandler:
		get_viewport().set_input_as_handled()
		var is_focused_changed: bool = _current_focus_block.focus_up()
		if not is_focused_changed:
			_block_navigation(-1)
	else:
		_block_navigation(-1)


func _handle_control_enter() -> void:
	if _current_focus_block is TableHandler:
		get_viewport().set_input_as_handled()
		_current_focus_block.add_row()
	else:
		_create_new_block(1)


func _handle_delete() -> void:
	get_viewport().set_input_as_handled()
	if _current_focus_block is TableHandler:
		_current_focus_block.delete_current_cell_content()
	else:
		_delete_current_block()


func _handle_review() -> void:
	_save_document()
	var new_review: ReviewHandler = REVIEW_CONTAINER.instantiate()
	new_review.lesson_dir = lesson_dir
	get_tree().get_root().add_child(new_review)
	hide()


func _handle_tab(new_block_placement: int) -> void:
	_current_focus_block.queue_free()
	_create_new_block(new_block_placement)


func _move_current_block(relative_position_to: int) -> void:
	var current_index: int = _current_focus_block.get_index()
	var max_index: int = %DocumentContainer.get_child_count() - 1
	var target_index: int = clamp(current_index + relative_position_to, 0, max_index)
	%DocumentContainer.move_child(_current_focus_block, target_index)


func _save_document() -> void:
	if get_viewport().gui_get_focus_owner():
		get_viewport().gui_get_focus_owner().release_focus()
		await get_tree().process_frame
	if lesson_dir:
		var err: String = DocumentHandler.save_document(lesson_dir, %DocumentContainer)
		if err:
			print("DocumentEditorHandler._save_document(): Failed to Save Document")
			return


func _update_topic_numbers() -> void:
	if not is_node_ready():
		await ready
	if %DocumentContainer == null or %ContentsContainer == null:
		return
	await get_tree().process_frame
	var current_topic_number: int = 0
	var current_sub_topic_number: int = 0
	for content: Node in %ContentsContainer.get_children():
		content.queue_free()
	for block: Node in %DocumentContainer.get_children():
		match block.block_type:
			"LESSON":
				current_topic_number = 0
				current_sub_topic_number = 0
				_create_content_label(block)
			"HEADER":
				current_topic_number += 1
				current_sub_topic_number = 0
				block.set_topic_number(current_topic_number, current_sub_topic_number)
				_create_content_label(block)
			"SUB_HEADER":
				current_sub_topic_number += 1
				block.set_topic_number(current_topic_number, current_sub_topic_number)
				_create_content_label(block)
