class_name UserDataHandler
extends Node

const SAVE_PATH: String = "user://ACEAppData.tres"

static func get_data() -> UserData:
	print("UserDataHandler.get_data(): Loading UserData from " + SAVE_PATH)
	if !FileAccess.file_exists(SAVE_PATH):
		printerr("UserDataHandler.get_data(): File does Not Exist. Creating File")
		var err: int = ResourceSaver.save(UserData.new(), SAVE_PATH)
		if err:
			printerr("UserDataHandler.get_data(): Failed to Create UserData")
			return
	
	var userData: UserData = ResourceLoader.load(SAVE_PATH)
	if userData == null:
		printerr("UserDataHandler.get_data(): Failed to Load UserData")
		return null
	
	if userData is not UserData:
		printerr("UserDataHandler.get_data(): Loaded Resource is not UserData")
		return null

	print("UserDataHandler.get_data(): Successfully Loaded UserData")
	return userData


static func save_new_data(type: String, data: Dictionary, doc_hash: int = 0) -> int:
	print("UserDataHandler.save_new_data(): Saving UserData at " + SAVE_PATH)
	var currentUserData: UserData = UserDataHandler.get_data()
	if currentUserData == null:
		print("UserDataHandler.save_new_data(): Aborting")
		return 1
	
	match type:
		"PATH":
			currentUserData.known_documents_paths.append(data.path)
		"PROGRESS":
			currentUserData.progresses[doc_hash] = data.progress
		"SETTING":
			currentUserData.settings[data.name] = data.value
	
	var err: int = ResourceSaver.save(currentUserData, SAVE_PATH)
	if err:
		printerr("UserDataHandler.save_new_data(): Failed to Save UserData with Err " + str(err))
		return 2
	
	return 0
