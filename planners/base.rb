class MainPlanner
   YAW_THRESHOLD = deg_to_rad(10)
   Z_THRESHOLD = 0.31

   describe("Simple Movement. Move for a certain distance in a certain direction at a certain speed at a certain depth. The depth can be reached before or while moving forward.").
        required_arg("z", "initial z value on which robot should rotate").
        optional_arg('forward_speed', 'if set to a non-zero value, the system will first go to position and then go forward for the specified duration at this speed').
        optional_arg('move_during_descent', 'if set to true and forward_speed to a non-zero value, the system will move even before having reached its specified heading and depth').
        optional_arg("duration", "how long we should stay at the specified depth/heading, in seconds").
        optional_arg("heading", "the wanted absolute heading. Set to nil to use the current heading").
        optional_arg("relative_heading", "adding a relative heading to the current one")

    method(:simple_move) do
        target_heading      = arguments[:heading]
        relative_heading    = arguments[:relative_heading]
        z                   = arguments[:z]
        duration            = arguments[:duration]
        forward_speed       = arguments[:forward_speed] || 0
        move_during_descent = arguments[:move_during_descent]

        descent_speed = { :x => 0, :y => 0 }
        if move_during_descent
            descent_speed[:x] = forward_speed
        end
        wait_speed    = { :x => forward_speed, :y => 0 }

        control = self.relative_position_control
        control.script do
            data_reader 'orientation', ['orientation_with_z', 'orientation_z_samples']
            data_writer 'motion_command', ['controller', 'motion_commands']

            wait_any command_child.start_event

            if target_heading.respond_to?(:call)
                execute { target_heading = target_heading.call }
            elsif !target_heading
                poll do
                    if o = orientation
                        target_heading = o.orientation.yaw
                        transition!
                    end
                end
            end

            execute do
                if relative_heading
                    target_heading += relative_heading
                end
                target_heading = normalize_angle(target_heading)

                command_child.disconnect_ports(controller_child, [['motion_command', 'motion_commands']])
                Plan.info "simple movement to yaw #{target_heading}, z #{z} with speed #{descent_speed}"
            end

            poll do
                motion_command.x_speed = descent_speed[:x]
                motion_command.y_speed = descent_speed[:y]
                motion_command.z = z
                motion_command.heading = target_heading
                write_motion_command

                if current_pose = self.orientation
                    current_heading = current_pose.orientation.yaw
                    heading_error = normalize_angle(current_heading - target_heading)
                    depth_error = current_pose.position.z - z

                    if heading_error.abs < YAW_THRESHOLD && depth_error.abs < Z_THRESHOLD
                        transition!
                    end
                else
                    Plan.warn "No orientation samples!"
                end
            end

            execute do
                Plan.info "reached specified station keeping position"
            end

            if duration
                execute do
                    Plan.info "waiting #{duration} with speed=#{wait_speed}"
                end
                start_time = nil
                execute { start_time = Time.now }
                poll do
                    motion_command.x_speed = wait_speed[:x]
                    motion_command.y_speed = wait_speed[:y]
                    motion_command.z = z
                    motion_command.heading = target_heading
                    write_motion_command

                    if time_over?(start_time, duration)
                        transition!
                    end
                end
            end

            emit :success
        end
    end

    # -------------------------------------------------------------------------

    describe("alignes to the given yaw and z depth and starts moving forward").
        required_arg("yaw", "initial heading for alignment").
        required_arg("z", "initial z value for alignment").
        optional_arg("speed", "forward velocity for motion").
        optional_arg("duration", "duration for this forward motion")
    method(:align_and_move) do
        yaw = arguments[:yaw]
        z = arguments[:z]
        speed = arguments[:speed]
        duration = arguments[:duration]

        control = self.relative_position_control
        control.script do
            #orientation_with_z_child.orientation_z_samples.data_reader
            #orientation = data_reader 'orientation_with_z', 'orientation_z_samples'
            data_reader 'orientation', ['orientation_with_z', 'orientation_z_samples']
            data_writer 'motion_command', ['controller', 'motion_commands']

            execute { yaw = yaw.call } if yaw.respond_to?(:call)

            wait_any command_child.start_event

            execute do
                command_child.disconnect_ports(controller_child, [['motion_command', 'motion_commands']])
                Plan.info "Align AUV to z #{z} and yaw #{yaw}"
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
            if duration and speed
                start_time = nil
                execute do
                    Plan.info "Moving forward with speed #{speed} for #{duration} seconds"
                    start_time = Time.now
                end

                poll do
                    motion_command.x_speed = speed
                    motion_command.y_speed = 0
                    motion_command.z = z
                    motion_command.heading = yaw
                    write_motion_command

                    transition! if (Time.now - start_time) > duration
                end
            end

            execute do
                Plan.info "Aligning and Moving finished successfully"
            end

            emit :success
        end
    end

    # -------------------------------------------------------------------------
   
    describe("relative strafing with motion_control_task").
        required_arg("yaw", "initial yaw for strafing").
        required_arg("z", "initial z value").
        required_arg("speed", "strafing speed on x direction").
        required_arg("duration", "strafing duration for this task")
    method(:align_and_strafe) do
        yaw = arguments[:yaw]
        z = arguments[:z]
        speed = arguments[:speed]
        duration = arguments[:duration]

        control = self.relative_position_control
        control.script do
            data_reader 'orientation', ['orientation_with_z', 'orientation_z_samples']
            data_writer 'motion_command', ['controller', 'motion_commands']

            execute { yaw = yaw.call } if yaw.respond_to?(:call)

            wait_any command_child.start_event

            execute do
                command_child.disconnect_ports(controller_child, [['motion_command', 'motion_commands']])
                Plan.info "Align AUV to z #{z} and yaw #{yaw}"
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
            if duration and speed
                start_time = nil
                execute do
                    Plan.info "Strafing with speed #{speed} for #{duration} seconds"
                    start_time = Time.now
                end

                poll do
                    motion_command.x_speed = 0
                    motion_command.y_speed = speed
                    motion_command.z = z
                    motion_command.heading = yaw
                    write_motion_command

                    transition! if (Time.now - start_time) > duration
                end
            end

            execute do
                Plan.info "Aligning and Strafing finished successfully"
            end

            emit :success
        end

    end

    # -------------------------------------------------------------------------
    
    describe("Navigation following defined waypoints").
        required_arg("waypoint", "next waypoint to follow").
        optional_arg("yaw", "navigating yaw for this movement").
        optional_arg("keep_time", "number of seconds keeping this waypoint")
    method(:navigate_to) do
        waypoint = arguments[:waypoint]
        yaw = if arguments[:yaw] then arguments[:yaw] else 10.0 end
        keep_time = if arguments[:keep_time] then arguments[:keep_time] else 1.0 end

        trajectory = []

        wp = Types::Base::Waypoint.new
        wp.position = waypoint
        wp.heading = yaw
        wp.tol_position = 3.0
        wp.tol_heading = 0.2

        trajectory << wp

        nav = self.navigation
        nav.script do 
            data_writer 'waypoint_command', ['navigator', 'trajectory']
            data_reader 'queue_size', ['navigator', 'queue_size']

            wait_any navigator_child.start_event
            wait_any control_child.command_child.start_event

            execute do
                waypoint_command << wp
            end

            poll_until(navigator_child.dynamic_navigation_event) do
                write_waypoint_command
            end 

            execute do
                Plan.info "Navigate to #{waypoint} with yaw #{yaw}"
            end

            poll_until(navigator_child.keep_waypoint_event) do
                sleep 0.1
            end

            execute do
                Plan.info "Keep this waypoint now for #{keep_time.to_f} seconds"
            end

            wait keep_time.to_f

            emit :success
        end
    end
 
    
    # -------------------------------------------------------------------------

    describe("relative forward motion until a wall is found via ping-pong sonar config").
        required_arg("yaw", "initial search direction of this motion method").
        required_arg("z", "initial z value of this search").
        required_arg("distance", "relative distance to a wall in front of avalon in m").
        required_arg("stabilization_time", "seconds for holding the wanted distance").
        optional_arg("timeout", "timeout when this method should be aborted")
    method(:align_frontal_distance) do
        yaw = arguments[:yaw]
        z = arguments[:z]
        distance = arguments[:distance] * 1000
        timeout = arguments[:timeout]
        wall_distance_stabilization = arguments[:stabilization_time]

        WALL_DISTANCE_THRESHOLD = 400
        MOVE_VARIANCE = 400.0 * 400.0

        sonar_distance = self.sonar_distance
        sonar_distance.script do
            data_reader 'wall_distance', ['detector', 'laserscan', 'new_feature']
            data_writer 'position_command', ['control', 'command', 'position_command'] 

            wait_any detector_child.start_event
            wait_any detector_child.servoing_child.start_event
            wait_any control_child.command_child.start_event

            execute do
                # disconnect SingleSonarServoing from AuvRelPosController
                #detector_child.disconnect_ports(control_child.command_child,
                #                                               [['relative_position_command', 'position_command']])

                Plan.info "Searching frontal distance to yaw #{yaw}, z #{z} until #{distance / 1000} meter"
            end

            poll do
                if wall_distance
                   if wall_distance.minRange > distance
                        emit :failed
                   else
                        transition!
                   end
               end
            end

            start_time = nil
            poll do
                position_command.heading = 0.0
                position_command.z = z
                position_command.x = 0.0
                position_command.y = 0.0

                if wall_distance && wall_distance.ranges[0] > 5
                   current_distance = wall_distance.ranges[0]
                   distance_error = (current_distance - distance)

                   position_command.x = distance_error

                   Robot.info "Current distance error #{distance_error}"

                   if distance_error.abs < WALL_DISTANCE_THRESHOLD
                       unless start_time
                           start_time = Time.now
                           Plan.info "Wanted distance reached. Stabilizing for #{wall_distance_stabilization} seconds" 
                       end

                       transition! if (Time.now - start_time) > wall_distance_stabilization
                   end
                end

                write_position_command
            end

            emit :success
        end
    end

    # -------------------------------------------------------------------------
end
