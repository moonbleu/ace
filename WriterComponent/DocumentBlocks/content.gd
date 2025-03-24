class_name ContentLabel
extends Label

@export var linked_to: Node


func _label_clicked() -> void:
	linked_to.focus_on_edit()
