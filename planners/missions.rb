class MainPlanner < Roby::Planning::Planner

    describe("dummy mission. to be used for temporary substitution of a real mission.").
        required_arg("msg", "short description")
    method(:dummy) do
        task = Planning::Dummy.new
        msg = arguments[:msg]        
        task.script do
            Plan.info "Dummy mission: #{msg}"
            emit :success
        end
        task
        
    end    
    
    describe("run a buoy servoing without cutting.").
        required_arg("yaw", "initial search direction").
        required_arg("z", "initial z value for finding a buoy").
        required_arg("speed", "search speed for a buoy").
        required_arg("search_timeout", "search timeout for finding buoy").
        required_arg("mission_timeout", "timeout for the whole mission incl. search").
        required_arg("waiting_time", "waiting time for receiving modem command").
        required_arg("mode", "strafing mode :serve_180 or :serve_360").
        optional_arg("strafe_distance", "strafing distance for :serve_180")
    method(:survey_buoy) do
        yaw = arguments[:yaw]
        z = arguments[:z]
        speed = arguments[:speed]
        search_timeout = arguments[:search_timeout]
        mission_timeout = arguments[:mission_timeout]
        waiting_time = arguments[:waiting_time]
        strafe_distance = arguments[:strafe_distance]
        mode = arguments[:mode]

        # Specify buoy task operations for later use
        buoy = self.buoy
        buoy_task = buoy.script do
            execute { yaw = yaw.call } if yaw.respond_to?(:call)

            data_reader 'orientation', ['control', 'orientation_with_z', 'orientation_z_samples']
            data_writer 'motion_command', ['control', 'controller', 'motion_commands']

            wait_any detector_child.start_event

            connection = nil
            start_time = nil
            
            # Take motion control away from detector task
            execute do
                start_time = Time.now
                
                buoy_detector = detector_child.detector_child
                buoy_servoing = detector_child.servoing_child                
                                
                connection = control_child.command_child.disconnect_ports(control_child.controller_child, [['motion_command', 'motion_commands']])
            
                buoy_servoing.orogen_task.strafe_angle = strafe_distance if strafe_distance
               
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

                if search_timeout and time_over?(start_time, search_timeout)
                    Plan.info "Buoy search timeout."
                    emit :success
                end

                # Buoy detected?
                if detector_child.buoy_detected?
                    # Give control back to detector task
                    Plan.info "Buoy detected: Start Servoing"
                    control_child.command_child.connect_ports(control_child.controller_child, connection)
                    transition!
                end

                write_motion_command
            end

            # start servoing around the buoy
            poll do
                if mission_timeout and time_over?(start_time, mission_timeout)
                    Plan.info "Buoy mission timeout."
                    emit :success
                end

                if detector_child.buoy_lost? 
                    # TODO: recovery behavior!
                    Plan.info "Buoy lost. Abort."
                    emit :failed
                end

                if detector_child.strafe_finished?
                    Plan.info "STRAFE_FINISHED emitted! Mission complete."
                    transition!
                end
            end

            emit :success
        end
    end
    
    

    describe("run a complete pipeline following using current alignment").
        required_arg("yaw", "initial search direction for pipeilne").
        required_arg("z", "initial z value for pipeline following").
        required_arg("speed", "searching velocity for finding pipeline").
        required_arg("follow_speed", "speed on pipeline following").
        optional_arg("prefered_yaw", "alignment yaw and enabling pipeline following").
        optional_arg("search_timeout", "timeout for searching pipeline").
        optional_arg("mission_timeout", "timeout for the whole pipeline following. expected to be greater than search_timeout.").
        optional_arg("do_safe_turn", "set to true if you want to do one safe turn and follow the pipe until the other end.").
        optional_arg("controlled_turn_on_pipe", "set to true if you want to do a controlled turn on the pipe as soon as possible. this is acquired by inverting the preferred heading.")
    method(:find_and_follow_pipeline) do
        z = arguments[:z]
        speed = arguments[:speed]
        search_timeout = arguments[:search_timeout] 
        yaw = arguments[:yaw]
        prefered_yaw = arguments[:prefered_yaw]
        follow_speed = arguments[:follow_speed]
        mission_timeout = arguments[:mission_timeout]
        do_safe_turn = arguments[:do_safe_turn]
        controlled_turn_on_pipe = arguments[:controlled_turn_on_pipe] || false
        
        PIPELINE_SEARCH_CANDIDATE_SPEED = if speed > 0 then 0.1 else -0.1 end
        #PIPELINE_SEARCH_CANDIDATE_SPEED = if follow_speed > 0 then 0.1 else -0.1 end
	
        #PIPELINE_DETECTOR_CHANNEL = 3

        pipeline = self.pipeline
        task = pipeline.script do
            data_reader 'pipeline_info', ['detector', 'offshorePipelineDetector', 'pipeline']
            data_writer 'motion_command', ['control', 'controller', 'motion_commands']

            connection = nil
            start_time = nil

            execute { yaw = yaw.call } if yaw.respond_to?(:call)
            execute { prefered_yaw = prefered_yaw.call } if prefered_yaw and prefered_yaw.respond_to?(:call)
            execute do
                start_time = Time.now
                
                 # Take away control from detector in order to move forward blind to search pipe
                 connection = control_child.command_child.disconnect_ports(control_child.controller_child, [['motion_command', 'motion_commands']])
                
                follower = detector_child.offshorePipelineDetector_child
                follower.orogen_task.default_x = follow_speed
                follower.orogen_task.weak_signal_x = 0.25 * follow_speed

                if controlled_turn_on_pipe
                    # set preferred heading later in order to avoid immediate align_auv
                    follower.orogen_task.prefered_heading = prefered_yaw if prefered_yaw #debug
                    follower.orogen_task.depth = z
                    control_child.command_child.connect_ports(control_child.controller_child, connection)
                    
                    Plan.info "Executing controlled turn on pipe on yaw #{yaw} with z #{z} using channel #{follower.orogen_task.use_channel}. Preferred yaw: #{prefered_yaw}"
                else
		    Plan.info "Overriding prefered heading to #{prefered_yaw}" if prefered_yaw
                    follower.orogen_task.prefered_heading = prefered_yaw if prefered_yaw
                    follower.orogen_task.depth = z

                    
                    #follower.orogen_task.use_channel = PIPELINE_DETECTOR_CHANNEL
                    Plan.info "Searching pipeline on yaw #{yaw} with z #{z} using channel #{follower.orogen_task.use_channel}. Preferred yaw: #{prefered_yaw}"
                
                end
            end
            wait_any detector_child.start_event
            wait_any control_child.command_child.start_event

            poll do
                if search_timeout and time_over?(start_time, search_timeout)
                    Plan.warn "Search timeout pipeline following (find_and_follow_pipeline)!"
                    emit :success
                end
               
                motion_command.heading = yaw
                motion_command.z = z
                motion_command.y_speed = 0
                #motion_command.x_speed = 0 # default for controlled_turn case

                last_event = detector_child.history.last
                if last_event.symbol == :check_candidate
                    motion_command.x_speed = PIPELINE_SEARCH_CANDIDATE_SPEED
                elsif controlled_turn_on_pipe
                    # We are already on the pipe so no need to find it.
                    if detector_child.follow_pipe? || detector_child.align_auv?
                        write_motion_command ## for z
                        transition!
                    end
                elsif detector_child.found_pipe? || detector_child.align_auv?
                    Plan.info "Pipeline detected and found"
                    transition!
                else
                    motion_command.x_speed = speed
                end
                write_motion_command
            end

            if prefered_yaw
                execute do
                   # set preferred heading => go to align_auv
                   follower = detector_child.offshorePipelineDetector_child
                   follower.orogen_task.prefered_heading = prefered_yaw if prefered_yaw
                   follower.orogen_task.default_x = follow_speed
                   follower.orogen_task.weak_signal_x = 0.25 * follow_speed
                   control_child.command_child.connect_ports(control_child.controller_child, connection)
                end

                #wait detector_child.follow_pipe_event
                poll_until detector_child.follow_pipe_event do
                    if mission_timeout and time_over?(start_time, mission_timeout)
                        Plan.warn "Mission timeout pipeline following (find_and_follow_pipeline)!"
                        emit :success
                    end
                end
                execute do
                    Plan.info "Following pipeline until END_OF_PIPE is occuring"
                end
                
                # Ensure that we do not perceive the pipeline end we are coming from
                execute do
                    wait 5
                end

                #wait detector_child.end_of_pipe_event
                poll_until detector_child.end_of_pipe_event do
                    if mission_timeout and time_over?(start_time, mission_timeout)
                        Plan.warn "Mission timeout pipeline following (find_and_follow_pipeline)!"
                        emit :success
                    end
                end

                execute do
                    Plan.info "Possible END_OF_PIPE detected"
                end
                
            end

            emit :success
        end

        task.on :success do |event|
            heading = event.task.detector_child.pipeline_heading
            if heading
                Plan.info "Storing current pipeline heading on END_OF_PIPE: #{heading * 180 / Math::PI} deg, #{heading} rad"
                State.pipeline_heading = heading
            else
                Plan.warn "Could not store current pipeline heading."
            end
        end
    end



    describe("simplified find, follow and turn on pipeline").
        required_arg("yaw", "initial search yaw for finding pipeline").
        required_arg("speed", "search speed for finding pipeline").
        required_arg("z", "initial z value for pipeline following").
        required_arg("prefered_yaw", "prefered heading on pipeline").
        optional_arg("turns", "number of turns on pipeline").
        optional_arg("search_timeout", "search timeout for finding pipeline").
        optional_arg("turn_timeout", "timeout for turning on end of pipeline")
        # TODO Mission Timeout!
    method(:find_follow_turn_pipeline) do
        z = arguments[:z]
        prefered_yaw = arguments[:prefered_yaw]
        speed = arguments[:speed]
        yaw = arguments[:yaw]
        search_timeout = arguments[:search_timeout]
        turn_timeout = arguments[:turn_timeout]
        turns = if arguments[:turns] then arguments[:turns] else 0 end

        start_follower = find_and_follow_pipeline(:yaw => yaw, 
                                                  :z => z, 
                                                  :prefered_yaw => prefered_yaw, 
                                                  :speed => speed,
                                                  :follow_speed => 0.4,
                                                  :search_timeout => search_timeout,
						  :mission_timeout => 500,
                                                  :do_safe_turn => false,
                                                  :controlled_turn_on_pipe => false)

        sequence = [start_follower]

        turns.times do |i|
            #move_back_blind = align_and_move(:yaw => proc { State.pipeline_heading }, 
            #                                 :z => z,
            #                                 :speed => -0.05, 
            #                                 :duration => 1.0)
            move_back_controlled = find_and_follow_pipeline(:yaw => proc { State.pipeline_heading }, 
                                                            :z => z, 
                                                            :prefered_yaw => prefered_yaw, 
                                                            :speed => -0.4,
                                                            :follow_speed => -0.3,
                                                            :search_timeout => 20, # TODO set correct timeout
                                                            :mission_timeout => 20,
                                                            :do_safe_turn => false,
                                                            :controlled_turn_on_pipe => false)
            #move_back_controlled.on :start do |event|
            #    on :follow_pipe do |event|
            #        Plan.info "Finished controlled back movement. Found pipe."
            #        emit :success
            #    end
            #end

            turn_follower = find_and_follow_pipeline(:yaw => proc { State.pipeline_heading }, 
                                       :z => z, 
                                       :speed => speed,
                                       :follow_speed => 0.4,
                                       :prefered_yaw => proc { normalize_angle(State.pipeline_heading + Math::PI + 0.1) }, #proc { normalize_angle(prefered_yaw + Math::PI)},
                                       :search_timeout => 40,  # TODO set correct timeout
                                       :mission_timeout => 180,
                                       :do_safe_turn => false,
                                       :controlled_turn_on_pipe => true)

            sequence << move_back_controlled << turn_follower
        end
        
        task = Planning::BaseTask.new
        task.add_task_sequence(sequence)
        task
    end



    describe("run a complete wall servoing using current alignment to wall").
        required_arg("z", "servoing depth").
        required_arg("corners", "number of serving corners").
        #optional_arg("speed", "servoing speed for wall survey").
        #optional_arg("initial_wall_yaw", "servoing wall in this direction").
        #optional_arg("servoing_wall_yaw", "direction for a wall in survey").
        #optional_arg("ref_distance", "reference distance to wall").
        optional_arg("timeout", "timeout after successful corner passing")        
    method(:survey_wall) do
        servoing_wall_yaw = arguments[:servoing_wall_yaw]
        z = arguments[:z]
        initial_wall_yaw = arguments[:initial_wall_yaw]
        speed = arguments[:speed]
        ref_distance = arguments[:ref_distance]
        corners = arguments[:corners]
        timeout = arguments[:timeout]

        wall_servoing = self.wall_right # TODO use method argument to choose wall servoing mode
        roby_task = wall_servoing.script do
            wait_any detector_child.start_event
            wait_any control_child.command_child.start_event

            execute do 
                survey = detector_child.servoing_child
                #survey.orogen_task.wall_distance = ref_distance if ref_distance
                #survey.orogen_task.servoing_wall_direction = servoing_wall_yaw if servoing_wall_yaw
                #survey.orogen_task.initial_wall_direction = initial_wall_yaw if initial_wall_yaw
                #survey.orogen_task.servoing_speed = speed if speed
                #survey.orogen_task.right_opening_angle = 0.5 * Math::PI
                #survey.orogen_task.left_opening_angle = 0.35 * Math::PI
                #survey.orogen_task.fixed_depth = z

                sonar = detector_child.sonar_child 

                if robot_name?(:simulation)
                    #Plan.info "Overwrite configuration on avalon_simulation::SonarTop"
                    #sonar.orogen_task.start_angle = 0.75 * Math::PI
                    #sonar.orogen_task.end_angle = 0.0
                    #sonar.orogen_task.maximum_distance = 10.0
                else
                    #Plan.info "Overwrite configuration on sonar_tritech::Micron"
                    #sonar_config = sonar.orogen_task.config
                    #sonar_config.rightLimit.rad = 0.0
                    #sonar_config.leftLimit.rad = 0.85 * Math::PI
                    #sonar_config.cont = 0.0
                    #sonar_config.initialGain = 0.5
                    #sonar_config.maximumDistance = 10.0
                    #sonar.orogen_task.config = sonar_config
                end
            end

            execute do
                Plan.info "Survey #{timeout} seconds until timeout"
            end

	    start_time = nil

	    execute do
	        start_time = Time.now
	    end

	    corner_counter = 0;
	    is_corner_detected = false;

        poll do
            if timeout and time_over?(start_time, timeout)
                Plan.warn "Mission timeout wall servoing (survey_wall)!"
                emit :success
            end
                
            if detector_child.misconfiguration?
                Plan.info "Misconfiguration failure on sonar found"
                emit :failed #  TODO handle this!
            end

		    if detector_child.detected_corner? and is_corner_detected == false
			    is_corner_detected = true
			    corner_counter += 1
			    Plan.info "Corner #{corner_counter} detected"
		    elsif !detector_child.detected_corner? and is_corner_detected == true
			    is_corner_detected = false
		    end

            # transition! if corners and corner_counter >= corners
        end

            emit :success
        end
    end

    describe("run a complete asv mission including pingersearch").
        #required_arg("z", "servoing depth").
        optional_arg("timeout","mission timeout in seconds")
    method(:pingersearch_and_asv) do
        #z = arguments[:z]
        timeout = arguments[:timeout]
        roby_task = self.asv_and_pinger.script do
            data_reader 'orientation', ['control', 'orientation_with_z', 'orientation_z_samples']
            data_writer 'surface_command', ['asv_detector', 'detector', 'do_surface']
            
            wait_any asv_detector_child.start_event
            wait_any pingersearch_child.start_event
            wait_any control_child.command_child.start_event

	        start_time = nil

	        execute do
                Plan.info "Starting autonomous ASV following."
	            start_time = Time.now
	        end

            poll do
                if asv_detector_child.standing? # TODO not safe yet. ensure that following took place or some timeout fired.
                    Plan.info "ASV is standing. Send surface command!"
                    surface_command_writer.write true
                end
                current_z = orientation.orientation.z
                if asv_detector_child.surfacing? and current_z > -1.0 # TODO make threshold
                    Plan.info "Surfaced! (Reached z threshold. current depth: #{current_z}"
                    emit :success
                end
                if timeout and time_over?(start_time, timeout)
                    Plan.info "ASV Following mission timeout. Abort."
                    emit :failed # TODO does this kill the whole mission sequence or just this mission?
                end
            end

            emit :success
        end
    end
    
    describe("Go forward until suitable distance to wall is reached. The deployment wall_front defines this distance.").
        optional_arg("mission_timeout","")
    method(:goto_wall) do
        mission_timeout = arguments[:mission_timeout]
        
        task = self.wall_front_align
        task.script do
            wait_any detector_child.start_event
            wait_any control_child.command_child.start_event
            
            execute do
                start_time = Time.now
                Plan.info "Going forward until we reach the wall."
            end
            
            poll_until detector_child.wall_servoing_event do
                if mission_timeout and time_over?(start_time, mission_timeout)
                    Plan.warn "Mission timeout! (goto_wall)"
                    emit :success
                end
            end
            
            emit :success
        end
    end
end
