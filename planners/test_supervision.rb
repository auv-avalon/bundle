require 'roby/tasks/simple'

class MainPlanner < Roby::Planning::Planner
    method(:test_mode_switching) do
        main = Roby::Tasks::Simple.new

        main.depends_on(pipeline = self.pipeline)
        main.depends_on(buoy     = self.buoy)
        main.depends_on(wall     = self.wall)

        buoy.should_start_after pipeline
        wall.should_start_after buoy

        pipeline.script do
            wait 5
            emit :success
        end

        buoy.script do
            wait 5
            emit :success
        end

        main
    end
end

