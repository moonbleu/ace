extends Node

signal response_updated(new_token: String)

enum Mode {NONE, CHATBOT, QUESTION, ANSWER_1, ANSWER_2, ANSWER_3, ANSWER_4, FEEDBACK, SUMMARY, FEEDBACK_SUMMARY}

var llm_queue: Array[int]
var llm_mode: Mode

var _chat_model: NobodyWhoModel = NobodyWhoModel.new()
var _chat_worker: NobodyWhoChat = NobodyWhoChat.new()
var _embedding_model: NobodyWhoModel = NobodyWhoModel.new()
var _embedding_worker: NobodyWhoEmbedding = NobodyWhoEmbedding.new()

func start_LLMs(lm_path: String, em_path: String) -> void:
	if lm_path and em_path:
		add_child(_chat_worker)
		add_child(_embedding_worker)
		var _conn1: int = _chat_worker.connect("response_finished", _llm_response_finished)
		var _conn2: int = _chat_worker.connect("response_updated", _llm_response_updated)
		_chat_model.model_path = lm_path
		_embedding_model.model_path = em_path
		_chat_worker.model_node = _chat_model
		_embedding_worker.model_node = _embedding_model
		_chat_worker.system_prompt = "
You are an LLM for a reviewing application, you will generate questions, answers, and feedback for the user.
You will answer the questions of the user and you will be given context around the question.
Don't answer that is contradictory from the context.
Stick to answering questions that the user asks.
MAKE YOUR ANSWERS DETAILED.
BASE YOUR ANSWERS ON THE CONTEXT AND CONVESATION HISTORY.
ANSWER THE QUESTION DIRECTLY WITHOUT ANY MENTIONS OF ANYTHING ELSE.
		"
		_chat_worker.start_worker()
		_embedding_worker.start_worker()
		return
	printerr("LLMHandler.start_LLMs(): Unable to Start Models")


func queue_for_llm(queue_mode: Mode) -> void:
	if llm_queue.is_empty():
		llm_queue.append(0)
		llm_mode = queue_mode
		return
	var queue_id: int = randi()
	while queue_id in llm_queue:
		queue_id = randi()
	llm_queue.append(queue_id)
	while llm_queue[0] != queue_id:
		await get_tree().process_frame
	if queue_mode == Mode.NONE:
		llm_queue.pop_front()
	llm_mode = queue_mode
	return


func _llm_response_updated(new_token: String) -> void:
	var _err: int = emit_signal("response_updated", new_token)


func _llm_response_finished(_response: String) -> void:
	llm_queue.pop_front()
	llm_mode = Mode.NONE


func embed(to_embed: String) -> PackedFloat32Array:
	return await _embedding_worker.embed(to_embed)


func direct_say(prompt: String) -> void:
	_chat_worker.say(prompt)


func generate_multiple_choice_question(context: String) -> void:
	_chat_worker.say("
GENERATE a question based on the context,
DO NOT GENERATE A TRUE OR FALSE QUESTION,
YOUR OUTPUT SHOULD ONLY BE A QUESTION,
DO NOT ADD ACCORDING TO THE PROVIDED INFORMATION OR ALONG THE LIKE,
DO NOT ASK IF THE INFORMATION IS TRUTHFUL OR NOT,
DO NOT ASK QUESTIONS THAT CANNOT BE DIRECTLY ANSWERED WITH THE PROVIDED CONTEXT
context: %s
	" % context)


func generate_true_or_false_question(context: String, is_correct: bool) -> void:
	var is_correct_str: String = "TRUE" if is_correct else "FALSE"
	_chat_worker.say("
GENERATE a TRUE OR FALSE question based on the context,
The answer to the question should be %s,
ONLY GENERATE A TRUE OR FALSE QUESTION,
DO NOT INCLUDE THE ANSWER,
GENERATE A QUESTION THAT CAN BE ANSWER WITH EITHER TRUE OR FALSE,
DO NOT ADD ACCORDING TO THE PROVIDED INFORMATION OR ALONG THE LIKE,
DO NOT ASK IF THE INFORMATION IS TRUTHFUL OR NOT,
DO NOT ASK QUESTIONS THAT CANNOT BE DIRECTLY ANSWERED WITH THE PROVIDED CONTEXT
context: %s
	" % [is_correct_str, context])


func generate_answer(question: String, is_correct: bool) -> void:
	var is_correct_str: String = "A CORRECT" if is_correct else "AN INCORRECT"
	_chat_worker.say("
Generate %s answer based on the following question '%s'
DO NOT SAY THE ANSWER IS CORRECT OR WRONG ONLY OUTPUT THE POSSIBLE ANSWER,
ONLY GENERATE %s ANSWER
	" % [is_correct_str, question, is_correct_str])
