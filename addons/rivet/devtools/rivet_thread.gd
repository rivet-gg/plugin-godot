signal finished(output: Variant)

var mutex: Mutex
var thread: Thread
var output: Variant = null

func wait_to_finish():
	await finished
	return output

func _init(fn: Callable) -> void:
	thread = Thread.new()
	mutex = Mutex.new()
	thread.start(func():
		var result = fn.call()
		mutex.lock()
		output = result
		call_deferred("emit_signal", "finished", result)
		mutex.unlock()
		return result
	)
