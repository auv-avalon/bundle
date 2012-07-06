class MainPlanner < Roby::Planning::Planner

    describe("test a mission")
    method(:mission_test) do
        moving = align_and_move(:yaw => 0.0, :z => -2.0)
        diveup = align_and_strafe(:yaw => 0.3, :z => -1.0)
        divedown = align_and_move(:yaw => 0.7, :z => -7.0)

        run = Planning::MissionRun.new
        run.design do
            m_move = mission("Moving", moving, 120.0)
            m_divedown = mission("Diving Down", divedown, 120.0)
            m_diveup = state(diveup)

            start m_move 
            finish m_divedown

            transition m_move, :success => m_diveup, :timeout => m_divedown
            transition m_diveup, :success => m_divedown

        end
    end
end
