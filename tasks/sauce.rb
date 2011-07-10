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

    class BuoyAndWall < Roby::Task
        terminates

        event :wall_timeout
        forward :wall_timeout => :failed
    end

    class CoolBuoyAndWall < Roby::Task
        terminates

        event :found_distance
        event :no_distance

        event :wall_acquisition_finished
        forward :found_distance => :wall_acquisition_finished
        forward :no_distance => :wall_acquisition_finished
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

        event :timeout
        forward :timeout => :failed
    end

    class ASVFromWall < Roby::Task
        terminates
    end

    class QualifWall < Roby::Task
        terminates
    end
end

