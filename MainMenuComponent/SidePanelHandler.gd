extends PanelContainer

const DOCUMENT_EDITOR: PackedScene = preload("res://WriterComponent/document_editor.tscn")
const DOCUMENTS_INFO_MENU: PackedScene = preload("res://Components/documents_info_menu.tscn")
const REVIEW_CONTAINER: PackedScene = preload("res://ReviewComponent/review_container.tscn")

func _ready() -> void:
	var dark_mode_node: ColorRect = $DarkMode
	remove_child(dark_mode_node)
	get_tree().get_root().add_child.call_deferred(dark_mode_node)
	get_tree().get_root().move_child.call_deferred(dark_mode_node, 0)
	var blf_node: ColorRect = $BlueLightFilter
	remove_child(blf_node)
	get_tree().get_root().add_child.call_deferred(blf_node)
	get_tree().get_root().move_child.call_deferred(blf_node, 1)
	var userData: UserData = UserDataHandler.get_data()
	for path: String in userData.known_documents_paths:
		var new_info_menu: DocumentInfoMenu = DOCUMENTS_INFO_MENU.instantiate()
		var d_hash: int = path.get_file().get_basename().hash()
		var d_progress: Dictionary = userData.progresses.get_or_add(d_hash, {})
		print(path.get_file().get_basename().hash())
		if d_progress.is_empty():
			new_info_menu.set_progress(0)
		else:
			var progress_summary: float = 0
			for i: int in d_progress.values():
				progress_summary += i / 3.0
				print(progress_summary)
			progress_summary /= d_progress.values().size()
			progress_summary *= -1
			progress_summary += 1
			print(progress_summary)
			new_info_menu.set_progress(progress_summary)
		
		new_info_menu.set_path(path)
		new_info_menu.set_title(path.get_file().get_basename().to_upper())
		var _conn1: int = new_info_menu.edit_pressed.connect(_load_document)
		var _conn2: int = new_info_menu.review_pressed.connect(_load_review)
		%FileList.add_child(new_info_menu)


func _load_review(path: String) -> void:
	var new_review: ReviewHandler = REVIEW_CONTAINER.instantiate()
	new_review.lesson_dir = path
	get_tree().get_root().add_child(new_review)
	hide()


func _show_new_picker() -> void:
	%NewFilePicker.show()


func _show_import_picker() -> void:
	%ImportFilePicker.show()


func _new_document(path: String) -> void:
	print("SidePanelHandler._new_document(): Creating New Document")
	var err: String = DocumentHandler.create_document(path)
	if err:
		print("SidePanelHandler._new_document(): Aborting Creating Document")
		return
	print("SidePanelHandler._new_document(): Created Document")
	_load_document(path)


func _load_document(path: String) -> void:
	print("SidePanelHandler._load_document(): Loading Document")
	print("SidePanelHandler._load_document(): Instancing Writer")
	var new_writer: DocumentEditorHandler = DOCUMENT_EDITOR.instantiate()
	new_writer.lesson_dir = path
	var load_document_err: String = new_writer.load_document(path)
	if load_document_err:
		print("SidePanelHandler._load_document(): Aborting Loading Document")
		print("SidePanelHandler._load_document(): Freeing Writer Instance")
		new_writer.queue_free()
		return
	print("SidePanelHandler._load_document(): Adding Writer to Tree")
	get_tree().get_root().add_child(new_writer)
	get_tree().get_root().get_node("MainMenu").hide()
	print("SidePanelHandler._load_document(): Loaded Document")
	var userData: UserData = UserDataHandler.get_data()
	if path not in userData.known_documents_paths:
		var err: int = UserDataHandler.save_new_data("PATH", {"path": path})
		if err:
			print("SidePanelHandler._load_document(): Failed to Save New Path")
			return
		print("SidePanelHandler._load_document(): Saved New Path")


func _on_settings_button_toggled(toggled_on: bool) -> void:
	$"../SettingsContainer".visible = toggled_on
	$"../FileSelectorContainer".visible = not toggled_on
	$VBoxContainer/SettingsButton.text = "Back" if toggled_on else "Settings"
