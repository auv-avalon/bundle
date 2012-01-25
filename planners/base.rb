class MainPlanner < Roby::Planning::Planner
    describe("alignes to the given yaw and z depth and starts moving forward").
        required_arg("yaw", "initial heading for alignment").
        required_arg("z", "initial z value for alignment").
        required_arg("forward_speed", "forward velocity for motion").
        required_arg("duration", "duration for this forward motion")
    method(:move) do
    end

    describe("relative forward motion until a buoy is found and aligned").
        required_arg("yaw", "initial search direction of this motion method").
        required_arg("z", "initial z value a buoy should be found").
        required_arg("forward_speed", "forward velocity for motion").
        required_arg("timeout", "timeout when the search should be aborted")
    method(:search_buoy) do
        # Can use move command for alignment and motion
    end

    decribe("relative forward motion until a pipeline is found").
        required_arg("yaw", "initial search direction of this motion method").
        required_arg("z", "initial z value a pipeline should be found").
        required_arg("forward_speed", "forward velocity for motion").
        required_arg("timeout", "timeout when this method should be aborted")
    method(:search_pipeline) do
        # Can use move command for alignment and motion
    end

    describe("relative forward motion until a wall is found via ping-pong sonar config").
        required_arg("yaw", "initial search direction of this motion method").
        required_arg("z", "initial z value of this search").
        required_arg("forward_speed", "forward velocity for motion").
        required_arg("distance", "relative distance to a wall in front of avalon").
        required_arg("angle_range", "scanning range (-angle_range/2, angle_range/2)  in front of avalon").
        required_arg("timeout", "timeout when this method should be aborted")
    method(:search_frontal_wall) do
        # Cam use move command for alignment and motion
        # angle_range = 0 would be a simple beam distance estimator
    end

    describe("alignment depending on a found pipeline").
        required_arg("prefered_heading", "aligning heading on a given pipeline")
    method(:align_on_pipeline) do
        # use pipeline detector for holding position on a pipeline and align
    end

end
