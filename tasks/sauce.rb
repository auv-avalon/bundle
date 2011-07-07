module SaucE
    class Mission < Roby::Task
        terminates
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
end

