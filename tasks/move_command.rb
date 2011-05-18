class MoveCommand < Roby::Task
	#give command as vector3d
	arguments :command
	
	event :start do |context|
		motion_control_tasks = plan.find_tasks(AvalonControl::MotionControlTask).
			with_child(self).to_value_set
		if motion_control_tasks.size > 1
			raise ArgumentError, "Cannot handle multiple Motioncontrollers"
		elsif
			@motion =  motion_control_tasks.first
			@motion_writer = data_writer 'motion_commands', 'motion'
			@motion_sample = data.writer.new_sample
			@motion_sample.x_speed = command[0]
			@motion_sample.y_speed = command[1]
			@motion_sample.z = command[2]
			@motion_sample.heading = 0
		end
	end

	poll do
		if @motion_writer && @motion
			@motion_writer.write(@motion_sample)
		end
	end
	#This task does not need any specific action to stop
	terminates
end
