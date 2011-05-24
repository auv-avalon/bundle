class TurnCommand < Roby::Task
	#give command as vector3d
	#arguments :command
	
	event :start do |context|
		state_estimator_tasks = plan.find_tasks(StateEstimator::Task).
			with_child(self).to_value_set
		if state_estimator_tasks.size > 1
			raise ArgumentError, "Cannot handle multiple Motioncontrollers"
		elsif
			@state = state_estimator_tasks.first
			@state_reader = @state.orientation_samples.reader
			@initial_orientation = @state_reader.read.orientation.to_euler(2,0,1)[0]
			@initial_depth = @state_reader.read.position[2]
		end


		motion_control_tasks = plan.find_tasks(AvalonControl::MotionControlTask).
			with_child(self).to_value_set
		if motion_control_tasks.size > 1
			raise ArgumentError, "Cannot handle multiple Motioncontrollers"
		elsif
			@motion =  motion_control_tasks.first
			@motion_writer = data_writer 'motion_commands', 'motion'
			@motion_sample = data.writer.new_sample
			@motion_sample.x_speed = 0
			@motion_sample.y_speed = 0
			@motion_sample.z = @initial_depth 
			@motion_sample.heading = @initial_orientation + Math::PI
		end
	end

	poll do
		if @motion_writer && @motion
			@motion_writer.write(@motion_sample)
		end

		if @state_reader && @initial_orientation
			if 10.0/180.0*Math::PI > (@state_reader.read.orientation.to_euler(2,0,1)[0] - (@initial_orientation + Math::PI)).abs
				pp "Stopping rotation beacase i'm reached the goal"
				emit :stop
			end
		end
	end
	#This task does not need any specific action to stop
	terminates
end
