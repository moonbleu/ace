class_name AnswerHandler
extends PanelContainer

signal multiple_choice_answer(answer_number: int)

@onready var label: Label = $VBoxContainer/Label
@onready var answer_1: CheckButton = $VBoxContainer/Answer1
@onready var answer_2: CheckButton = $VBoxContainer/Answer2
@onready var answer_3: CheckButton = $VBoxContainer/Answer3
@onready var answer_4: CheckButton = $VBoxContainer/Answer4
@onready var feedback: Label = $VBoxContainer/Feedback
@onready var v_box_container: VBoxContainer = $VBoxContainer
@onready var generating_choices: Label = $VBoxContainer/GeneratingChoices

var is_immediate_signal: bool = false
var _current_answer: Variant
var _has_answered: bool = false

func _ready() -> void:
	var randomized_list: Array = [answer_1, answer_2, answer_3, answer_4]
	randomized_list.shuffle()
	for node: Node in v_box_container.get_children():
		if node is CheckButton:
			v_box_container.remove_child(node)
	
	for button: CheckButton in randomized_list:
		v_box_container.add_child(button)
	
	v_box_container.move_child(feedback, v_box_container.get_child_count() - 1)


func show_answers() -> void:
	answer_1.show()
	answer_2.show()
	answer_3.show()
	answer_4.show()
	generating_choices.hide()


func show_generation_progress() -> void:
	if generating_choices.visible:
		generating_choices.text += "."
	else:
		generating_choices.show()


func handle_answer(answer: Variant, signal_name: Signal) -> void:
	_current_answer = answer
	if is_immediate_signal:
		signal_name.emit(answer)
		feedback.show()
		_has_answered = true


func _buttons_reset() -> void:
	answer_1.button_pressed = false
	answer_2.button_pressed = false
	answer_3.button_pressed = false
	answer_4.button_pressed = false


func get_answer() -> Variant:
	feedback.show()
	_has_answered = true
	return _current_answer


func _on_answer_1_pressed() -> void:
	if not _has_answered:
		handle_answer(1, multiple_choice_answer)
		_buttons_reset()
		answer_1.button_pressed = true


func _on_answer_2_pressed() -> void:
	if not _has_answered:
		handle_answer(2, multiple_choice_answer)
		_buttons_reset()
		answer_2.button_pressed = true


func _on_answer_3_pressed() -> void:
	if not _has_answered:
		handle_answer(3, multiple_choice_answer)
		_buttons_reset()
		answer_3.button_pressed = true


func _on_answer_4_pressed() -> void:
	if not _has_answered:
		handle_answer(4, multiple_choice_answer)
		_buttons_reset()
		answer_4.button_pressed = true
