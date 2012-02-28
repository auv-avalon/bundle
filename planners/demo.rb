class MainPlanner < Roby::Planning::Planner
    describe("run a complete autonomous mission for studiobad")
    method(:demo_autonomous_run, :returns => Planning::Mission) do
        main = Planning::Mission.new

        main
    end
end
