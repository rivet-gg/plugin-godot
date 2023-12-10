var semaphore: Semaphore
var thread: Thread
var mutex: Mutex
var should_exit_thread: bool = false
var callable: Callable
var last_output: Variant

signal finished()

func _init():
	mutex = Mutex.new()
	semaphore = Semaphore.new()

	thread = Thread.new()
	thread.start(_thread_loop)
	
func wait_to_finish():
	await finished
	return last_output

func cleanup():
	mutex.lock()
	should_exit_thread = true
	mutex.unlock()
 	# notify thread
	semaphore.post()
	thread.wait_to_finish()
	
func _thread_loop():
	while true:
		semaphore.wait()
		
		mutex.lock()
		var should_exit: bool = should_exit_thread
		mutex.unlock()
		
		if should_exit:
			break
		
		mutex.lock()
		var fn: Callable = callable
		last_output = null
		mutex.unlock()
		
		var output = fn.call()
		mutex.lock()
		last_output = output
		finished.emit()
		mutex.unlock()

func execute(fn: Callable):
	callable = fn
	semaphore.post()

#func _notification(what: int) -> void:
	#if what == NOTIFICATION_PREDELETE:
		#cancel_free()
		#cleanup()
		#free()
