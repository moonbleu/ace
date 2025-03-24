class_name TableHandler
extends GridContainer

signal focus_status_changed(block: Node, status: bool)

const CELL: PackedScene = preload("res://WriterComponent/DocumentBlocks/cell.tscn")

@export var block_type: String

var _current_focus_cell: TextHandler


func focus_on_edit() -> void:
	get_child(get_child_count() - 1).focus_on_edit()


func set_data(new_data: Dictionary) -> void:
	columns = new_data.columns
	for cell_data: String in new_data.cells_data:
		var new_cell: Node = CELL.instantiate()
		new_cell.set_data({"text": cell_data})
		new_cell.focus_status_changed.connect(_change_focus_cell)
		add_child(new_cell)


func get_block_data() -> Dictionary:
	var cells_data: Array
	for cell: TextHandler in get_children():
		cells_data.append(cell.get_block_data().text)
	return {"type": block_type, "columns": columns, "cells_data": cells_data}


func add_formatting(prefix: String, suffix: String) -> void:
	_current_focus_cell.add_formatting(prefix, suffix)


func _change_focus_cell(cell: TextHandler, status: bool) -> void:
	if status == true:
		_current_focus_cell = cell
		focus_status_changed.emit(self, true)
	elif _current_focus_cell == cell:
		focus_status_changed.emit(self, false)
		_current_focus_cell = null


func add_row() -> void:
	var current_row: int = ceili(_current_focus_cell.get_index() / float(columns))
	var new_row_start: int = current_row * columns + 1
	for i: int in range(0, columns):
		var new_cell: TextHandler = CELL.instantiate()
		add_child(new_cell)
		move_child(new_cell, new_row_start + i)
		var err: int = new_cell.focus_status_changed.connect(_change_focus_cell)
		if err:
			printerr("WriterHandler.create_new_block(): Failed to Connect with Err " + str(err))
	var _focused_down: bool = focus_down()


func add_column() -> void:
	var num_rows: int = ceili(get_child_count() / float(columns))
	var column_start: int = _current_focus_cell.get_index() % columns + 1
	columns += 1
	for i: int in range(0, num_rows):
		var new_cell: TextHandler = CELL.instantiate()
		add_child(new_cell)
		move_child(new_cell, i * columns + column_start)
		var err: int = new_cell.focus_status_changed.connect(_change_focus_cell)
		if err:
			printerr("WriterHandler.create_new_block(): Failed to Connect with Err " + str(err))
	focus_right()


func focus_up() -> bool:
	if _current_focus_cell.get_index() - columns > -1:
		get_child(_current_focus_cell.get_index() - columns).focus_on_edit()
		return true
	return false


func focus_down() -> bool:
	if _current_focus_cell.get_index() + columns < get_child_count():
		get_child(_current_focus_cell.get_index() + columns).focus_on_edit()
		return true
	return false


func focus_right() -> void:
	if _current_focus_cell.get_index() + 1 < get_child_count():
		get_child(_current_focus_cell.get_index() + 1).focus_on_edit()


func focus_left() -> void:
	if _current_focus_cell.get_index() > 0:
		get_child(_current_focus_cell.get_index() - 1).focus_on_edit()


func delete_current_cell_content() -> void:
	_current_focus_cell.set_data({"text": ""})


func delete_row() -> bool:
	var rows: int = get_child_count() % columns
	if rows == 1:
		return false
	var row_start: int = (_current_focus_cell.get_index() % columns) * columns
	if row_start == 0:
		var _focused_down: bool = focus_down()
	else:
		var _focused_up: bool = focus_up()
	for i: int in range(0, columns):
		get_child(row_start + i).queue_free()
	return true


func delete_column() -> bool:
	if columns == 1:
		return false
	var rows: int = get_child_count() % columns
	var column_start: int = _current_focus_cell.get_index() % columns
	if column_start == 0:
		focus_right()
	else:
		focus_left()
	for i: int in range(0, rows):
		get_child(i * columns + column_start).queue_free()
	columns -= 1
	return true


func set_topic_number(_new_topic_number: String) -> void:
	pass
