extends RefCounted
## A wrapper around Thread that allows you to wait for the thread to finish and get the result.
## 
## @experimental

signal finished(output: Variant)
signal killed()

var _mutex: Mutex
var _thread: Thread
var _is_killed: bool = false

## Result of the thread.
var output: Variant = null

## Returns the output of the thread.
func wait_to_finish():
	await finished
	return output

func _init(fn: Callable) -> void:
	_thread = Thread.new()
	_mutex = Mutex.new()
	_thread.start(func():
		var result = fn.call()
		_mutex.lock()
		if not _is_killed:
			output = result
			call_deferred("emit_signal", "finished", result)
		_mutex.unlock()
		return result
	)

func kill() -> void:
	_mutex.lock()
	_is_killed = true
	call_deferred("emit_signal", "killed")
	_mutex.unlock()