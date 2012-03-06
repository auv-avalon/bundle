class MainPlanner < Roby::Planning::Planner
   YAW_THRESHOLD = 10 * Math::PI / 180.0
   Z_THRESHOLD = 0.3

   describe("simple movement").
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
                if target_heading > Math::PI then target_heading -= 2*Math::PI
                elsif target_heading < -Math::PI then target_heading += 2*Math::PI
                end

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
                    heading_error = current_heading - target_heading
                    if heading_error > Math::PI then heading_error -= (2 * Math::PI)
                    elsif heading_error < -Math::PI then heading_error += (2 * Math::PI)
                    end

                    depth_error = current_pose.position.z - z

                    if heading_error.abs < YAW_THRESHOLD && depth_error.abs < Z_THRESHOLD
                        transition!
                    end
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

                    if Time.now - start_time > duration
                        transition!
                    end
                end
            end

            emit :success
        end
    end


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

        control = self.relative_position_control
        control.script do
            data_reader 'orientation', ['orientation_with_z', 'orientation_z_samples']
            data_writer 'motion_command', ['controller', 'motion_commands']

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
            if duration and forward_speed and forward_speed > 0.0
                start_time = nil
                execute do
                    Plan.info "Moving forward with speed #{forward_speed} for #{duration} seconds"
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

            execute do
                Plan.info "Aligning and Moving finished successfully"
            end

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
                position_command.heading = yaw
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

    describe("alignment depending on a found pipeline").
        required_arg("prefered_heading", "aligning heading on a given pipeline")
    method(:align_on_pipeline) do
        # use pipeline detector for holding position on a pipeline and align
    end

    # -------------------------------------------------------------------------
end
