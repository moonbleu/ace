class_name DocumentHandler
extends Node

const CURRENT_FILE_VERSION: int = 1

static func create_document(file_path: String) -> String:
	print("DocumentHandler.new_create_document(): Creating Document at " + file_path)
	var document: Document = Document.new()
	document.data.append({"type": "LESSON", "text": ""})
	document.metadata.file_version = CURRENT_FILE_VERSION
	var err: int = ResourceSaver.save(document, file_path)
	if err:
		printerr(
			"DocumentHandler.new_create_document(): Failed to Create Document with Err " + str(err)
		)
		return "Failed to Create Document with Err " + str(err)

	print("DocumentHandler.new_create_document(): Created Document ")
	return ""


static func get_document(file_path: String) -> Document:
	print("DocumentHandler.get_document(): Loading Document from " + file_path)
	if !FileAccess.file_exists(file_path):
		printerr("DocumentHandler.get_document(): File does not exist")
		return null

	var document: Document = ResourceLoader.load(file_path)
	if document == null:
		printerr("DocumentHandler.get_document(): Failed to Load Document")
		return null

	if document is not Document:
		printerr("DocumentHandler.get_document(): Loaded Resource is not a Document")
		return null
	
	if document.metadata.get("file_version") == null:
		document.metadata.get_or_add("file_version", 1)
	
	print("DocumentHandler.get_document(): Successfully Loaded Document")
	return document


static func save_document(file_path: String, document_container: Node) -> String:
	print("DocumentHandler.save_document(): Saving Document at " + file_path)
	if !FileAccess.file_exists(file_path):
		printerr("DocumentHandler.save_document(): File does not exist")
		return "DocumentHandler.save_document(): File does not exist"

	var document: Resource = Document.new()
	for block: Node in document_container.get_children():
		document.data.append(block.get_block_data())
		print("DocumentHandler.save_document(): Got Data of Block with Type " + block.block_type)

	document.metadata.file_version = CURRENT_FILE_VERSION
	var err: int = ResourceSaver.save(document, file_path)
	if err:
		printerr("DocumentHandler.save_document(): Failed to Save Document with Err " + str(err))
		return "Failed to Save Document with Err " + str(err)

	print("DocumentHandler.save_document(): Successfully Saved Document")
	return ""
