class MainPlanner
    describe("alignes to the given yaw and z depth and starts moving forward").
        required_arg("yaw", "initial heading for alignment").
        required_arg("z", "initial z value for alignment").
        required_arg("forward_speed", "forward velocity for motion").
        optional_arg("duration", "duration for this forward motion")
    method(:move) do
        yaw = arguments[:yaw]
        z = arguments[:z]
        forward_speed = arguments[:forward_speed]
        duration = arguments[:duration]

        YAW_THRESHOLD = 10 * Math::PI / 180.0
        Z_THRESHOLD = 0.3

        control = Cmp::ControlLoop.use('command' => AuvRelPosController::Task).as_plan
        control.script do
            data_reader 'orientation', ['orientation_with_z', 'orientation_z_samples']
            data_writer 'motion_command', ['controller', 'command']

            wait_any command_child.start_event

            command_child.disconnect_ports(controller_child, [['motion_command', 'command']])
        end

        # align to the given yaw and z value in this movement
        poll do
            motion_command.x_speed = 0
            motion_command.y_speed = 0
            motion_command.z = z
            write_motion_command

            if pose = self.orientation
                current_yaw = pose.orientation.yaw
                current_depth = pose.position.z

                yaw_error = normalize_angle(current_yaw - yaw)
                depth_error = current_depth - z

                transition! if yaw_error.abs < YAW_THRESHOLD and depth_error.abs < Z_THRESHOLD                
             end
        end

        # move the aligned auv in respect to z, yaw by given forward_speed and duration
        if duration and forward_speed > 0.0
            start_time = nil
            execute do
                start_time = Time.now
            end

            poll do
                motion_command.x_speed = forward_speed
                motion_command.y_speed = 0
                motion_command.z = z
                motion_command.heading = yaw
                write_motion_command

                transition! if (Time.now - start_time) > duration
            end
        end
        emit :success
    end

    # -------------------------------------------------------------------------

    describe("relative forward motion until a buoy is found and aligned").
        required_arg("yaw", "initial search direction of this motion method").
        required_arg("z", "initial z value a buoy should be found").
        required_arg("forward_speed", "forward velocity for motion").
        required_arg("timeout", "timeout when the search should be aborted")
    method(:search_buoy) do
        # Can use move command for alignment and motion
    end

    # -------------------------------------------------------------------------

    describe("relative forward motion until a pipeline is found").
        required_arg("yaw", "initial search direction of this motion method").
        required_arg("z", "initial z value a pipeline should be found").
        required_arg("forward_speed", "forward velocity for motion").
        required_arg("timeout", "timeout when this method should be aborted")
    method(:search_pipeline) do
        # Can use move command for alignment and motion
    end

    # -------------------------------------------------------------------------

    describe("relative forward motion until a wall is found via ping-pong sonar config").
        required_arg("yaw", "initial search direction of this motion method").
        required_arg("z", "initial z value of this search").
        required_arg("forward_speed", "forward velocity for motion").
        required_arg("distance", "relative distance to a wall in front of avalon").
        required_arg("angle_range", "scanning range (-angle_range/2, angle_range/2)  in front of avalon").
        required_arg("timeout", "timeout when this method should be aborted")
    method(:search_frontal_wall) do
        # Can use move command for alignment and motion
        # angle_range = 0 would be a simple beam distance estimator
    end

    # -------------------------------------------------------------------------

    describe("alignment depending on a found pipeline").
        required_arg("prefered_heading", "aligning heading on a given pipeline")
    method(:align_on_pipeline) do
        # use pipeline detector for holding position on a pipeline and align
    end

    # -------------------------------------------------------------------------
end
