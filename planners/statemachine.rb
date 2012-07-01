class MainPlanner < Roby::Planning::Planner

    describe("test method for state machine based missions")
    method(:state_run) do
        dive_down = align_and_move(:yaw => 0.0, :z => -5.0)
        dive_up = align_and_move(:yaw => 0.5 * Math::PI, :z => -1.0)

        run = Planning::AutonomousRun.new
        run.design do 
            start(dive_down)

            transition(dive_down, :success, dive_up)

            finish(dive_up)
        end
    end
end
