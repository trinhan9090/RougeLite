extends SceneTree
func _initialize() -> void:call_deferred("run")
func run() -> void:
 await process_frame
 var failures: int=0
 var checks: Array[bool]=[
  DisplayServer.window_get_mode()==DisplayServer.WINDOW_MODE_MAXIMIZED,
  not DisplayServer.window_get_flag(DisplayServer.WINDOW_FLAG_BORDERLESS),
  not DisplayServer.window_get_flag(DisplayServer.WINDOW_FLAG_RESIZE_DISABLED),
  ProjectSettings.get_setting("display/window/size/viewport_width")==1920,
  ProjectSettings.get_setting("display/window/size/viewport_height")==1080]
 for index in range(checks.size()):
  print("PASS " if checks[index] else "FAIL ",index)
  if not checks[index]:failures+=1
 print("RESULT native window: 5 checks, ",failures," failures")
 quit(failures)
