class_name ReviewHandler
extends PanelContainer

const ANSWER_HANDLER_CONTAINER: PackedScene = preload("res://ReviewComponent/answer_handler_container.tscn")

@onready var history: TextEdit = $HBCont/ChatbotContainer/VBoxContainer/ScrollContainer/History
@onready var user_input: LineEdit = $HBCont/ChatbotContainer/VBoxContainer/HBoxContainer/UserInput
@onready var chatbot_container: PanelContainer = $HBCont/ChatbotContainer
@onready var flashcards_container: PanelContainer = $HBCont/FlashcardsContainer
@onready var lessons_list: VBoxContainer = $HBCont/LessonsSelector/LessonsList
@onready var confirm_button: Button = $HBCont/LessonsSelector/LessonsList/ConfirmButton
@onready var side_panel_container: PanelContainer = $HBCont/SidePanelContainer
@onready var lessons_selector: PanelContainer = $HBCont/LessonsSelector
@onready var summary_container: PanelContainer = $HBCont/SummaryContainer
@onready var summary: TextEdit = $HBCont/SummaryContainer/ScrollContainer/Summary
@onready var mock_exam_container: PanelContainer = $HBCont/MockExamContainer
@onready var flashcards_place: VBoxContainer = $HBCont/FlashcardsContainer/FlashcardsPlace
@onready var generate_flashcard_button: Button = $HBCont/FlashcardsContainer/FlashcardsPlace/GenerateFlashcardButton
@onready var amount_of_questions: HBoxContainer = $HBCont/MockExamContainer/ScrollContainer/VBoxContainer/AmountOfQuestions
@onready var generate_mock_exam_button: Button = $HBCont/MockExamContainer/ScrollContainer/VBoxContainer/GenerateMockExamButton
@onready var submit_button: Button = $HBCont/MockExamContainer/ScrollContainer/VBoxContainer/SubmitButton
@onready var feedback: Label = $HBCont/MockExamContainer/ScrollContainer/VBoxContainer/Feedback
@onready var v_box_container: VBoxContainer = $HBCont/MockExamContainer/ScrollContainer/VBoxContainer
@onready var new_mock_exam_button: Button = $HBCont/MockExamContainer/ScrollContainer/VBoxContainer/NewMockExamButton

var lesson_dir: String
var _question_history: Array[Dictionary]
var _lesson_embeddings: Array[Dictionary]
var _progress_hash: Dictionary[int, int]
var _current_answer_handler: AnswerHandler
var _d_hash: int

#-------------------------------------------------------------------------------
# Godot Fuctions
#-------------------------------------------------------------------------------

func _input(_event: InputEvent) -> void:
	if visible:
		if Input.is_action_just_pressed("ui_accept") and user_input.text:
			var question: String = user_input.text
			_user_asked(question)


func _ready() -> void:
	var _conn: int = LLMHandler.connect("response_updated", _llm_response_updated)
	side_panel_container.hide()
	chatbot_container.hide()
	flashcards_container.hide()
	summary_container.hide()
	mock_exam_container.hide()
	lessons_selector.show()
	_generate_embeddings()

#-------------------------------------------------------------------------------
# Helper Fuctions
#-------------------------------------------------------------------------------

func _save_progress() -> void:
	var err: int = UserDataHandler.save_new_data("PROGRESS", {"progress": _progress_hash}, _d_hash)
	if err:
		printerr("ReviewHandler._save_progress(): Failed to save progress (err %d)" % err)
	else:
		print("ReviewHandler._save_progress(): Progress saved.")


func _pick_weighted_embedding() -> Dictionary:
	var total_weight: int = 0
	for embed: Dictionary in _lesson_embeddings:
		var weight: int = _progress_hash.get(embed["t_hash"], 5)
		total_weight += weight
	
	var random_val: int = randi() % total_weight
	for embed: Dictionary in _lesson_embeddings:
		var weight: int = _progress_hash.get(embed["t_hash"], 5)
		random_val -= weight
		if random_val < 0:
			return embed
	
	return _lesson_embeddings[0]


func _update_question_history(question: String) -> void:
	if _question_history.size() >= 3:
		_question_history.pop_front()
	
	var question_embedding: PackedFloat32Array = await LLMHandler.embed(question)
	_question_history.append({
		"text": question,
		"embedding": question_embedding,
		"type": "question"
	})


func _generate_embeddings() -> void:
	_d_hash = lesson_dir.get_file().get_basename().hash()
	var document: Document = DocumentHandler.get_document(lesson_dir)
	var progress: Dictionary = UserDataHandler.get_data().progresses.get_or_add(_d_hash, {})
	var embeddings: Array[Dictionary]
	var excluded_lessons: Array[String]
	var lesson: String
	var header: String
	var sub_header: String
	var embedding_num: int = 0
	for block: Dictionary in document.data:
		if block.type == "LESSON":
			var lesson_button: CheckButton = CheckButton.new()
			lesson_button.text = block.text
			lesson_button.button_pressed = true
			lessons_list.add_child(lesson_button)
	
	lessons_list.move_child(confirm_button, lessons_list.get_child_count())
	await confirm_button.pressed
	for lesson_title: Button in lessons_list.get_children():
		if lesson_title is CheckButton and not lesson_title.button_pressed:
			excluded_lessons.append(lesson_title.text + ": ")
	
	for block: Dictionary in document.data:
		match block.type:
			"LESSON":
				lesson = block.text + ": "
				header = ""
				sub_header = ""
			"HEADER":
				header = block.text + ": "
				sub_header = ""
			"SUB_HEADER":
				sub_header = block.text + ": "
			"DESCRIPTION":
				if lesson not in excluded_lessons:
					var to_embed: String = lesson + header + sub_header + block.text
					var t_hash: int = to_embed.hash()
					var embed: PackedFloat32Array = await LLMHandler.embed(to_embed)
					_progress_hash[t_hash] = progress.get_or_add(t_hash, 3)
					embeddings.append({"text": to_embed, "embedding": embed, "t_hash": t_hash})
					embedding_num += 1
	
	_lesson_embeddings = embeddings
	print("ReviewHandler.generate_embeddings(): Generated %d embeddings" % embedding_num)
	side_panel_container.show()
	chatbot_container.show()
	lessons_selector.hide()


func generate_augmented_prompt(question: String) -> String:
	var question_embedding: PackedFloat32Array = await LLMHandler.embed(question)
	var all_contexts: Array[Dictionary] = _lesson_embeddings.duplicate()
	all_contexts.append_array(_question_history)
	var similarities: Array[Dictionary] = []
	var max_similarity: float = 0.9975
	for entry: Dictionary in all_contexts:
		var embedding_entry: PackedFloat32Array = entry["embedding"]
		var sim: float = NobodyWhoEmbedding.cosine_similarity(question_embedding, embedding_entry)
		if sim <= max_similarity:
			similarities.append({
				"similarity": sim,
				"text": entry["text"],
				"type": entry.get("type", "lesson")
			})
	similarities.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return a["similarity"] > b["similarity"]
	)
	var top_contexts: Array[Dictionary] = similarities.slice(0, 5)
	var context_str: String = ""
	for ctx: Dictionary in top_contexts:
		var prefix: String = "[Lesson] " if ctx["type"] == "lesson" else "[Previous Question] "
		context_str += prefix + ctx["text"] + "\n"
	
	var augmented_prompt: String = "
Consider both the lesson content and our conversation history:
{context}
Current Question: {question}
Answer:
	".format({"context": context_str, "question": question})
	return augmented_prompt

#-------------------------------------------------------------------------------
# Handler Fuctions
#-------------------------------------------------------------------------------

func _llm_response_updated(token: String) -> void:
	match LLMHandler.llm_mode:
		LLMHandler.Mode.CHATBOT:
			history.text += token
		LLMHandler.Mode.QUESTION:
			_current_answer_handler.label.text += token
		LLMHandler.Mode.ANSWER_1:
			_current_answer_handler.answer_1.text += token
		LLMHandler.Mode.ANSWER_2:
			_current_answer_handler.answer_2.text += token
		LLMHandler.Mode.ANSWER_3:
			_current_answer_handler.answer_3.text += token
		LLMHandler.Mode.ANSWER_4:
			_current_answer_handler.answer_4.text += token
		LLMHandler.Mode.FEEDBACK:
			_current_answer_handler.feedback.text += token
		LLMHandler.Mode.SUMMARY:
			summary.text += token
		LLMHandler.Mode.FEEDBACK_SUMMARY:
			$HBCont/MockExamContainer/ScrollContainer/VBoxContainer/Feedback.text += token


func _on_button_pressed() -> void:
	var question: String = user_input.text
	_user_asked(question)


func _on_chat_button_pressed() -> void:
	flashcards_container.hide()
	summary_container.hide()
	mock_exam_container.hide()
	chatbot_container.show()


func _on_flash_cards_button_pressed() -> void:
	flashcards_container.show()
	summary_container.hide()
	chatbot_container.hide()
	mock_exam_container.hide()


func _on_generate_flashcard_button_pressed() -> void:
	_generate_flashcard()


func _on_mock_test_button_pressed() -> void:
	flashcards_container.hide()
	summary_container.hide()
	chatbot_container.hide()
	mock_exam_container.show()


func _on_generate_mock_exam_button_pressed() -> void:
	_generate_mock_exam()


func _on_new_mock_exam_button_pressed() -> void:
	for node: Node in v_box_container.get_children():
		if node is AnswerHandler:
			node.queue_free()
	amount_of_questions.show()
	generate_mock_exam_button.show()
	feedback.hide()
	new_mock_exam_button.hide()


func _on_summary_button_pressed() -> void:
	chatbot_container.hide()
	flashcards_container.hide()
	mock_exam_container.hide()
	summary_container.show()
	if summary.text == "":
		_generate_summary()

#-------------------------------------------------------------------------------
# LLM Fuctions
#-------------------------------------------------------------------------------

func _generate_summary() -> void:
	LLMHandler.queue_for_llm(LLMHandler.Mode.SUMMARY)
	var full_text: String = ""
	for lesson: Dictionary in _lesson_embeddings:
		full_text += lesson["text"] + "\n"
	LLMHandler.direct_say("Summarize the following: %s" % full_text)


func _generate_question(context: String, parent: Node, is_immediate_signal: bool) -> void:
	#while _current_answer_handler != null:
		#await get_tree().process_frame
	var new_answer_handler: AnswerHandler = ANSWER_HANDLER_CONTAINER.instantiate()
	new_answer_handler.is_immediate_signal = is_immediate_signal
	parent.add_child(new_answer_handler)
	_current_answer_handler = new_answer_handler
	await LLMHandler.queue_for_llm(LLMHandler.Mode.QUESTION)
	LLMHandler.generate_multiple_choice_question(context)
	await LLMHandler.queue_for_llm(LLMHandler.Mode.ANSWER_1)
	_current_answer_handler.show_generation_progress()
	LLMHandler.generate_answer(context, true)
	await LLMHandler.queue_for_llm(LLMHandler.Mode.ANSWER_2)
	_current_answer_handler.show_generation_progress()
	LLMHandler.generate_answer(context, false)
	await LLMHandler.queue_for_llm(LLMHandler.Mode.ANSWER_3)
	_current_answer_handler.show_generation_progress()
	LLMHandler.generate_answer(context, false)
	await LLMHandler.queue_for_llm(LLMHandler.Mode.ANSWER_4)
	_current_answer_handler.show_generation_progress()
	LLMHandler.generate_answer(context, false)
	await LLMHandler.queue_for_llm(LLMHandler.Mode.NONE)
	_current_answer_handler.show_answers()


func _generate_flashcard() -> void:
	generate_flashcard_button.hide()
	for node: Node in flashcards_place.get_children():
		if node is AnswerHandler:
			node.queue_free()
	var selected_embedding: Dictionary = _pick_weighted_embedding()
	var context: String = selected_embedding["text"]
	var question_t_hash: int = selected_embedding["t_hash"]
	await _generate_question(context, flashcards_place, true)
	var user_answer: int = await _current_answer_handler.multiple_choice_answer
	var user_answer_button: Button
	match user_answer:
		1: user_answer_button = _current_answer_handler.answer_1
		2: user_answer_button = _current_answer_handler.answer_2
		3: user_answer_button = _current_answer_handler.answer_3
		4: user_answer_button = _current_answer_handler.answer_4
	if user_answer == 1:
		_progress_hash[question_t_hash] -= 1
		await LLMHandler.queue_for_llm(LLMHandler.Mode.FEEDBACK)
		LLMHandler.direct_say("Praise the user for the answer '%s' which is correct." % user_answer_button.text)
	else:
		_progress_hash[question_t_hash] += 1
		await LLMHandler.queue_for_llm(LLMHandler.Mode.FEEDBACK)
		LLMHandler.direct_say("Why is the answer '%s' incorrect?" % user_answer_button.text)
	await LLMHandler.queue_for_llm(LLMHandler.Mode.NONE)
	_progress_hash[question_t_hash] = clamp(_progress_hash[question_t_hash], 1, 3)
	_save_progress()
	flashcards_place.move_child(generate_flashcard_button, 1)
	generate_flashcard_button.show()


func _generate_mock_exam() -> void:
	amount_of_questions.hide()
	generate_mock_exam_button.hide()
	for i:int in range(0, amount_of_questions.get_node("HSlider").value):
		var selected_embedding: Dictionary = _pick_weighted_embedding()
		var context: String = selected_embedding["text"]
		await _generate_question(context, v_box_container, false)
		#_current_answer_handler = null
	v_box_container.move_child(submit_button, v_box_container.get_child_count() - 1)
	submit_button.show()
	await submit_button.pressed
	submit_button.hide()
	for node: Node in v_box_container.get_children():
		if node is AnswerHandler:
			_current_answer_handler = node
			var user_answer: Variant = node.get_answer()
			if user_answer != null:
				var user_answer_button: Button
				match user_answer:
					1: user_answer_button = _current_answer_handler.answer_1
					2: user_answer_button = _current_answer_handler.answer_2
					3: user_answer_button = _current_answer_handler.answer_3
					4: user_answer_button = _current_answer_handler.answer_4
				if user_answer == 1:
					await LLMHandler.queue_for_llm(LLMHandler.Mode.FEEDBACK)
					LLMHandler.direct_say("Praise the user for the answer '%s' which is correct." % user_answer_button.text)
				else:
					await LLMHandler.queue_for_llm(LLMHandler.Mode.FEEDBACK)
					LLMHandler.direct_say("Why is the answer '%s' incorrect?" % user_answer_button.text)
				await LLMHandler.queue_for_llm(LLMHandler.Mode.NONE)
	#_current_answer_handler = null
	LLMHandler.queue_for_llm(LLMHandler.Mode.FEEDBACK_SUMMARY)
	LLMHandler.direct_say("
Summarize what the user needs to improve upon based on their answers, if they did well, praise them.
	")
	v_box_container.move_child(feedback, v_box_container.get_child_count() - 1)
	feedback.text = ""
	feedback.show()
	v_box_container.move_child(new_mock_exam_button, v_box_container.get_child_count() - 1)
	new_mock_exam_button.show()


func _user_asked(question: String) -> void:
	await LLMHandler.queue_for_llm(LLMHandler.Mode.CHATBOT)
	history.text = ""
	await _update_question_history(question)
	var augmented_prompt: String = await generate_augmented_prompt(question)
	LLMHandler.direct_say(augmented_prompt)
