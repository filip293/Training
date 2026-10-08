extends Node


# Added 'pausable' parameter that defaults to true
func calltime(time: float, pausable: bool = true) -> Signal:
	var timer := Timer.new()
	
  
	timer.process_mode = Node.PROCESS_MODE_PAUSABLE 
	
		
	timer.wait_time = time
	timer.one_shot = true
	
	timer.timeout.connect(timer.queue_free)
	
	add_child(timer)
	timer.start()
	
	return timer.timeout
