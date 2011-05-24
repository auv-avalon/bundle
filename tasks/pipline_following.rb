class PiplineFollowing < Roby::Task
	#give command as vector3d
	#arguments :command
	
	event :start do |context|
		@cmpPiplineDetector = plan.add(Cmp::PipelineDetector)
		detector_tasks = plan.find_tasks(OffshorePipelineDetector::Task).
			with_child(self).to_value_set
		if detector_tasks.size > 1
			raise ArgumentError, "Cannot handle multiple Motioncontrollers"
		elsif
			@piplineDetector = detector_tasks.first
			@piplineDetector.on(:SEARCH_PIPE){ |event| plan.add(MoveCommand)}
			@piplineDetector.on(:FOLLOW_PIPE){ |event| plan.add(Cmp::PipelineFollower)}
			@piplineDetector.on(:END_OF_PIPE){ |event| 
				@turner = plan.add(TurnCommand)
				@turner.on(:STOP){ |event| 
					plan.add(MoveCommand)
				}
			}
		end
	end
	#This task does not need any specific action to stop
	terminates
end
