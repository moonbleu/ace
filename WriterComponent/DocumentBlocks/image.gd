class_name ImageHandler
extends HBoxContainer

signal focus_status_changed(block: Node, status: bool)

@export var block_type: String
@export var edit: VSlider
@export var image_rect: TextureRect

var _is_focused: bool = false


func _on_edit_focus_entered() -> void:
	if !_is_focused:
		_is_focused = true
		edit.show()
		focus_status_changed.emit(self, true)


func _on_edit_focus_exited() -> void:
	set_data(
		{
			"image": image_rect.texture.get_image(),
			"size": image_rect.custom_minimum_size.y,
			"compressed": false,
		}
	)
	focus_status_changed.emit(self, false)
	edit.hide()


func focus_on_edit() -> void:
	edit.grab_focus()


func set_data(new_data: Dictionary) -> void:
	_is_focused = false
	var image: Image
	if new_data.compressed:
		var width: int = new_data.width
		var height: int = new_data.height
		var mipmap: bool = new_data.mipmap
		var format: int = new_data.format
		var image_bytes: PackedByteArray = new_data.image.decompress(new_data.buffer_size, 2)
		image = Image.create_from_data(width, height, mipmap, format, image_bytes)
	else:
		image = new_data.image
	var texture: Texture = ImageTexture.create_from_image(image)
	image_rect.texture = texture
	if new_data.has("size"):
		image_rect.custom_minimum_size.y = new_data.size
		edit.value = new_data.size


func get_block_data() -> Dictionary:
	return {
		"type": block_type,
		"image": image_rect.texture.get_image().get_data().compress(2),
		"size": image_rect.custom_minimum_size.y,
		"compressed": true,
		"width": image_rect.texture.get_image().get_width(),
		"height": image_rect.texture.get_image().get_height(),
		"mipmap": image_rect.texture.get_image().has_mipmaps(),
		"format": image_rect.texture.get_image().get_format(),
		"buffer_size": image_rect.texture.get_image().get_data().size(),
	}


func _on_edit_value_changed(value: float) -> void:
	image_rect.custom_minimum_size.y = edit.value


func set_topic_number(_new_topic_number: String) -> void:
	pass


func add_formatting(_prefix: String, _suffix: String) -> void:
	pass
