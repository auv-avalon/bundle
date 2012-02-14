class MainPlanner < Roby::Planning::Planner
        describe("alignes to the given yaw and z depth and starts moving forward").
        required_arg("yaw", "initial heading for alignment").
        required_arg("z", "initial z value for alignment").
        optional_arg("forward_speed", "forward velocity for motion").
        optional_arg("duration", "duration for this forward motion")
    method(:align_and_move) do
        yaw = arguments[:yaw]
        z = arguments[:z]
        forward_speed = arguments[:forward_speed]
        duration = arguments[:duration]

        YAW_THRESHOLD = 10 * Math::PI / 180.0
        Z_THRESHOLD = 0.3

        control = self.relative_position_control
        control.script do
            data_reader 'orientation', ['orientation_with_z', 'orientation_z_samples']
            data_writer 'motion_command', ['controller', 'command']

            wait_any command_child.start_event

            execute do
                command_child.disconnect_ports(controller_child, [['motion_command', 'command']])
            end

            # align to the given yaw and z value in this movement
            poll do
                motion_command.x_speed = 0
                motion_command.y_speed = 0
                motion_command.z = z
                motion_command.heading = yaw
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
            if duration and forward_speed and forward_speed > 0.0
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
        optional_arg("timeout", "timeout when this method should be aborted")
    method(:search_pipeline) do
        # Can use move command for alignment and motion
        z = arguments[:z]
        forward_speed = arguments[:forward_speed]
        yaw = arguments[:yaw]
        timeout = timeout[:timeout]

        PIPELINE_SEARCH_CANDIDATE_SPEED = if forward_speed > 0 then 0.1 else -0.1 end
        PIPELINE_PREFERED_HEADING = 0.0

        pipeline = self.pipeline
        pipeline.script do
            # Define a 'orientation_reader' and 'orientation' methods that allow
            # access to control.pose.orientation_z_samples
            data_reader 'orientation', ['control', 'orientation_with_z', 'orientation_z_samples']
            data_reader 'pipeline_servoing_command', ['detector', 'relative_position_command']
            data_reader 'pipeline_info', ['detector', 'offshorePipelineDetector', 'pipeline']

            # Define 'motion_command_writer', 'motion_command' and 'write_motion_command'
            data_writer 'motion_command', ['control', 'controller', 'command']
            data_writer 'rel_pos_command', ['control', 'command', 'position_command']

            if timeout
                execute do
                    detector_child.found_pipe_event.
                        should_emit_after detector_child.start_event,
                        :max_t => timeout
                end
            end

            wait_any detector_child.start_event
            wait_any control_child.command_child.start_event

            execute do
                control_child.command_child.disconnect_ports(control_child.controller_child, [['motion_command', 'command']])
                pipeline_detector = detector_child.offshorePipelineDetector_child
                pipeline_detector.orogen_task.depth = z
                pipeline_detector.orogen_task.prefered_heading = PIPELINE_PREFERED_HEADING
            end

            poll do
                motion_command.heading = yaw
                motion_command.z = z
                motion_command.y_speed = 0

                last_event = detector_child.history.last
                if last_event.symbol == :check_candidate
                    motion_command.x_speed = PIPELINE_SEARCH_CANDIDATE_SPEED
                elsif detector_child.found_pipe?
                    transition!
                else
                    motion_command.x_speed = forward_speed
                end
                write_motion_command

            end
        end

        emit :success
    end

    # -------------------------------------------------------------------------

    describe("relative forward motion until a wall is found via ping-pong sonar config").
        required_arg("yaw", "initial search direction of this motion method").
        required_arg("z", "initial z value of this search").
        required_arg("forward_speed", "forward velocity for motion").
        required_arg("distance", "relative distance to a wall in front of avalon in m").
        optional_arg("timeout", "timeout when this method should be aborted")
    method(:search_frontal_distance) do
        yaw = arguments[:yaw]
        z = arguments[:z]
        forward_speed = arguments[:forward_speed]
        distance = arguments[:distance] * 1000
        timeout = arguments[:timeout]

        WALL_DISTANCE_THRESHOLD = 0.4

        alignment = align_and_move(:yaw => yaw, :z => z)

        sonar_distance = self.sonar_distance

        move_forward = sonar_distance.script do
            data_reader 'wall_distance', ['laser_scan_provider', 'laserscan']
            data_writer 'motion_command', ['controller', 'command']

            wait_any command_child.start_event

            execute do
                # disconnect AuvRelPosController
                command_child.disconnect_ports(controller_child, [['motion_command', 'command']])
            end

            poll do 
                if wall_distance
                   if wall_distance.minRange > distance
                        emit :failure
                   else
                        transition!
                   end
               end
            end

            poll do
                motion_command.heading = yaw
                motion_command.z = z
                motion_command.y_speed = 0
                motion_command.x_speed = forward_speed
                write_motion_command

                if wall_distance
                   current_distance = wall_distance.ranges[0]
                   distance_error = (current_distance - distance).abs

                   transition! if distance_error < WALL_DISTANCE_THRESHOLD
                end
            end

            emit :success
        end

        move_forward.depends_on alignment
        move_forward.should_start_after alignment
        move_forward
    end

    # -------------------------------------------------------------------------

    describe("alignment depending on a found pipeline").
        required_arg("prefered_heading", "aligning heading on a given pipeline")
    method(:align_on_pipeline) do
        # use pipeline detector for holding position on a pipeline and align
    end

    # -------------------------------------------------------------------------
end
