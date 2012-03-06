class MainPlanner < Roby::Planning::Planner
    describe("run a complete buoy servoing with cutting given a found buoy using current alignment").
        required_arg("yaw", "initial search direction").
        required_arg("z", "initial z value for finding a buoy").
        required_arg("speed", "search speed for a buoy").
        optional_arg("mode", ":serve_180, :serve_360 (180 or 360 degree servoing").
        optional_arg("search_timeout", "timeout for automatically cutting mode").
        optional_arg("survey_distance", "distance to a buoy").
        optional_arg("cut_timeout", "force cut after a specific time")
    method(:survey_and_cut_buoy) do
        yaw = arguments[:yaw]
        z = arguments[:z]
        speed = arguments[:forward_speed]
        mode = arguments[:mode]
        servey_distance = arguments[:servey_distance]
        search_timeout = arguments[:search_timeout]
        cut_timeout = arguments[:cut_timeout]

        # Specify alignment for later use
        alignment = align_and_move(:yaw => yaw, :z => z)

        CUTTING_TIME_INTERVAL = 3

        # Specify buoy task operations for later use
        buoy = self.buoy
        buoy_task = buoy.script do
            Plan.info "Debug: in Buoy Script"

            data_reader 'orientation', ['control', 'orientation_with_z', 'orientation_z_samples']
            data_writer 'buoy_cutting_command', ['detector', 'detector', 'force_cutting']
            data_writer 'motion_command', ['control', 'controller', 'motion_commands']

            wait_any detector_child.start_event

            if search_timeout
                execute do
                    detector_child.buoy_detected_event.
                        should_emit_after(detector_child.start_event, 
                                          :max_t => search_timeout)
                end
            end

            connection = nil
            
            # Take motion control away from detector task
            execute do
                start_time = Time.now
                connection = control_child.command_child.disconnect_ports(control_child.controller_child, [['motion_command', 'motion_commands']])
                buoy_detector = detector_child.detector_child
                buoy_detector.orogen_task.depth = z
                buoy_detector.orogen_task.max_buoy_distance = servey_distance if servey_distance

                if mode
                   buoy_detector.orogen_task.strafe_around = true if mode == :serve_360
                   buoy_detector.orogen_task.strafe_around = false if mode == :serve_180
                end
                
                Plan.info "Searching for buoy on yaw #{yaw} with z #{z}. Going forward."
            end

            poll do
                # Move forward
                motion_command.heading = yaw
                motion_command.z = z
                motion_command.x_speed = speed
                motion_command.y_speed = 0

                ## Handle events
                last_event = detector_child.history.last

                # Buoy detected?
                if detector_child.buoy_detected?
                    # Give control back to detector task
                    Plan.info "Buoy detected"
                    control_child.command_child.connect_ports(control_child.controller_child, connection)
                    transition!
                end

                write_motion_command
            end

            if mode
                start_time = nil
                
                poll do
                    # Check for mission timeout
                    if cut_timeout and time_over?(start_time, cut_timeout)
                        Plan.info "Start force cutting to the buoy"

                        poll do
                            buoy_cutting_command = true
                            write_buoy_cutting_command

                            transition! if time_over?(start_time, cut_timeout + CUTTING_TIME_INTERVAL) or detector_child.cutting_success?
                        end

                        transition!
                    end

                    if detector_child.buoy_lost? 
                        Plan.info "Buoy lost. Abort."
                        emit :failed
                    end
                end
            end

            emit :success
        end

        # Create and execute sequence of previously specified actions
        base_task = Planning::BaseTask.new
        base_task.add_task_sequence([alignment, buoy_task])
        base_task

    end


    describe("run a complete pipeline following using current alignment").
        required_arg("z", "initial z value for pipeline following").
        required_arg("prefered_yaw", "prefered heading on pipeline").
        required_arg("stabilization_time", "time of stabilization of the pipeline").
        optional_arg("timeout", "timeout for aborting pipeline following")
    method(:find_and_follow_pipeline) do
        z = arguments[:z]
        timeout = arguments[:timeout] 
        prefered_heading = arguments[:prefered_yaw]
        stabilization_time = arguments[:stabilization_time]

        pipeline = self.pipeline
        pipeline.script do
            if timeout
                execute do
                    detector_child.found_pipe_event.should_emit_after detector_child.start_event,
                    :max_t => timeout
                end
            end

            wait_any detector_child.start_event
            wait_any control_child.command_child.start_event

            execute do
                detector_child.offshorePipelineDetector_child.orogen_task.prefered_heading = normalize_angle(prefered_heading)
                Plan.info "Start aligning AUV for pipeline following"
            end

            wait detector_child.follow_pipe_event

            execute do
                Plan.info "Following pipeline until END_OF_PIPE is occuring"
            end

            wait detector_child.weak_signal_event

            execute do
                Plan.info "Possible END_OF_PIPE detected via WEAK_SIGNAL"
            end

            emit :success
        end
    end

    describe("find, follow and turn on pipeline").
        required_arg("z", "initial z value for pipeline following").
        required_arg("prefered_yaw", "prefered heading on pipeline").
        required_arg("stabilization_time", "time of stabilization of the pipeline").
        required_arg("turns", "number of turns on pipeline")
    method(:follow_and_turn_pipeline) do
        z = arguments[:z]
        prefered_yaw = arguments[:prefered_yaw]
        stabilization_time = arguments[:stabilization_time]
        turns = arguments[:turns]

        start_follower = follow_pipeline(:z => z, :prefered_yaw => prefered_yaw, 
                                         :stabilization_time => stabilization_time)
        
        sequence = [start_follower]

        turns.times do |i|
            angle = normalize_angle(prefered_yaw + (i + 1) * Math::PI)
            turner = search_pipeline(:z => z, :yaw => angle - Math::PI, :forward_speed => -0.8, :prefered_yaw => angle)
            follower = follow_pipeline(:z => z, 
                                       :prefered_yaw => angle, 
                                       :stabilization_time => stabilization_time)
            sequence << turner << follower
        end

        task = Planning::BaseTask.new
        task.add_task_sequence(sequence)
        task
    end

    describe("run a complete wall servoing using current alignment to wall").
        required_arg("corners", "number of serving corners").
        optional_arg("speed", "servoing speed for wall survey").
        optional_arg("initial_wall_yaw", "servoing wall in this direction").
        optional_arg("servoing_wall_yaw", "direction for a wall in survey").
        optional_arg("ref_distance", "reference distance to wall").
        optional_arg("timeout", "timeout after successful corner passing")        
    method(:survey_wall) do
        yaw = arguments[:servoing_wall_yaw]
        wall = arguments[:initial_wall_yaw]
        speed = arguments[:speed]
        ref_distance = arguments[:ref_distance]
        corners = arguments[:corners]
        timeout = arguments[:timeout]

        PASSING_CORNER_TIMEOUT = 4

        wall_servoing = self.wall
        wall_servoing.script do
            execute do 
                survey = detector_child.servoing_child
                survey.orogen_task.wall_distance = ref_distance if ref_distance
                survey.orogen_task.servoing_wall_direction = yaw if yaw
                survey.orogen_task.initial_wall_direction = wall if wall
                survey.orogen_task.servoing_speed = speed if speed

                Plan.info "Start wall servoing over #{corners} corners"
            end

            wait_any detector_child.start_event
            wait_any control_child.command_child.start_event

            corners.times do |i|
                wait detector_child.servoing_child.detected_corner_event
                wait detector_child.servoing_child.wall_servoing_event
                wait PASSING_CORNER_TIMEOUT
                wait detector_child.servoing_child.wall_servoing_event

                execute do
                    Plan.info "Corner #{i} passed, remaining #{corners - i} times"
                end
            end

            execute do
                Plan.info "Survey #{timeout} seconds until finish"
            end

            wait timeout
            emit :success
        end
    end
end
