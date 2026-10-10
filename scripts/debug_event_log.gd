extends RefCounted

const MAX_BYTES := 1048576

static func append_event(path: String, message: String) -> void:
	var log := FileAccess.open(path, FileAccess.READ_WRITE)
	if log == null:
		log = FileAccess.open(path, FileAccess.WRITE_READ)
	if log == null:
		return
	if log.get_length() > MAX_BYTES:
		log.close()
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
		log = FileAccess.open(path, FileAccess.WRITE_READ)
		if log == null:
			return
	log.seek_end()
	log.store_line(JSON.stringify({"time": Time.get_datetime_string_from_system(), "event": message}))
	log.close()
