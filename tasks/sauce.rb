module SaucE
    class Mission < Roby::Task
        terminates

	on :stop do |event|
	    Robot.emergency_surfacing
	end
    end

    class PipelineAndGates < Roby::Task
        terminates
    end

    class LookForBuoy < Roby::Task
        terminates
        event :found
        forward :found => :success
        event :not_found
        forward :not_found => :success
    end

    class Wall < Roby::Task
        terminates
    end

    class QualifWall < Roby::Task
        terminates
    end
end

