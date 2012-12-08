class MainPlanner < Roby::Planning::Planner

    describe("test a mission")
    method(:mission_test) do
        moving = align_and_move(:yaw => 0.0, :z => -2.0)
        diveup = align_and_strafe(:yaw => 0.3, :z => -1.0)
        divedown = align_and_move(:yaw => 0.7, :z => -4.0)
        error_task = align_and_move(:yaw => 0.0, :z => -3.0)

        run = Planning::MissionRun.new
        run.design do
            start moving
            finish divedown
            finish error_task

            transition moving, :success => diveup, :failed => error_task
            transition diveup, :success => divedown
        end
    end
end
