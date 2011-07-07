# The main planner. A planner of this model is automatically added in the
# Interface planner list.
class MainPlanner < Roby::Planning::Planner
    STOPPING_DURATION = 4 # Seconds needed to stop the vehicle from max speed

    PIPELINE_STABILIZATION_TIME = 10
    describe("moves forward and turns on pipeline following if a pipeline is detected").
        required_arg("heading", "initial heading for first searching the pipeline").
        required_arg("z", "the Z value at which we should search for the pipeline").
        required_arg("speed", "the forward speed at which we should search for the pipeline").
        required_arg("expected_pipeline_heading", "the general heading of the pipeline. Does not have to be precise.").
        optional_arg('pipeline_activation_threshold', 'wait for the pipeline to cover this portion of the image before giving control to the pipeline follower (between 0 and 1)')
    method(:find_and_follow_pipeline) do
        z       = arguments[:z]
        speed   = arguments[:speed]
        heading = arguments[:heading]
        expected_pipeline_heading = arguments[:expected_pipeline_heading]
        pipeline_activation_threshold = arguments[:pipeline_activation_threshold]
        timeout = arguments[:timeout]

        # Get a task representing the define('pipeline')
        pipeline = self.pipeline

        # Get (orocos) task context of pipeline detector
        #pipeline_detector_task = pipeline.detector_child

        # Set default speed
        #pipeline_detector_task.orogen_task.default_x = speed
        #
        checking_candidate_speed =
            if speed > 0 then CHECKING_CANDIDATE_SPEED
            else -CHECKING_CANDIDATE_SPEED
            end

        # Code the actual actions
        pipeline.script do
            setup_logger(Robot)

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

            # <blabla>_child
            #    returns the child named 'blabla' from the receiver
            #
            #    i.e. control_child => returns the Cmp::ControlLoop
            #         control_child.command_child => returns  the AUVMotionController
            #
            # <blabla>_port
            #    returns the port named 'blabla' from the receiver
            #         control_child.command_child.motion_command_port => returns motion_command_port from the AUVMotionController

            with_description "starting find_and_follow_pipeline" do
                wait_any control_child.command_child.start_event
                execute do
                    control_child.command_child.motion_command_port.disconnect_from control_child.controller_child.command_port
                    pipeline_follower = detector_child.offshorePipelineDetector_child
                    pipeline_follower.orogen_task.depth = z

                    if !expected_pipeline_heading && State.pipeline_heading?
                        expected_pipeline_heading = State.pipeline_heading
                        if speed < 0
                            expected_pipeline_heading =
                                if expected_pipeline_heading > 0
                                    expected_pipeline_heading - Math::PI
                                else expected_pipeline_heading + Math::PI
                            end
                        end
                    end

                    if expected_pipeline_heading
                        Robot.info "find_and_follow_pipeline: expected heading is #{expected_pipeline_heading * 180 / Math::PI}deg"
                        pipeline_follower.orogen_task.prefered_heading = expected_pipeline_heading
                    end
                end
            end

	    if !heading
                describe "find_and_follow_pipeline: autodetecting search heading"
	    	poll do
		    if o = orientation
		    	heading = o.orientation.yaw
                        transition!
		    end
		end
	    end

            describe "find_and_follow_pipeline: moving forward until a candidate is found"
            poll_until detector_child.check_candidate_event do
              motion_command.heading = heading
              motion_command.z = z
              motion_command.x_speed = speed
              motion_command.y_speed = 0
              write_motion_command
            end

            describe "find_and_follow_pipeline: found a candidate, slowing down"
            poll_until detector_child.align_auv_event do
              motion_command.x_speed = checking_candidate_speed
              write_motion_command
            end

            if pipeline_activation_threshold
                with_description "find_and_follow_pipeline: waiting for the pipeline to cover the image before switching to following" do
                    poll do
                        motion_command.x_speed = checking_candidate_speed
                        write_motion_command

                        if (p = pipeline_info) && p.disruption < (1 - pipeline_activation_threshold)
                            transition!
                        else
                            Robot.info "find_and_follow_pipeline: coverage=#{1 - p.disruption}"
                        end
                    end
                end
            end

            describe "find_and_follow_pipeline: starting visual servoing for pipeline"
            execute do
                auv_relpos_controller = control_child.command_child
                auv_relpos_controller.motion_command_port.connect_to control_child.controller_child.command_port
                Robot.info "Robot is aligning. Wait until done."
            end
            wait detector_child.follow_pipe_event

            describe "find_and_follow_pipeline: following the pipe until end_of_pipe"
            wait detector_child.end_of_pipe_event

            describe "find_and_follow_pipeline: pipeline end reached, waiting 5 seconds for stability"
            wait PIPELINE_STABILIZATION_TIME

            describe "find_and_follow_pipeline: finished"
            emit :success
        end
    end

    # -------------------------------------------------------------------------

    BUOY_RESCUE_ANGLE_RANGE = Math::PI

    describe("move forward as long as a buoy is found by the detector and start
              servoing and later strafing around the buoy").
        required_arg("heading", "initial heading where search a buoy").
        required_arg("distance", "wished distance to the buoy for servoing").
        required_arg("speed", "forward speed for searching a buoy").
        required_arg("z", "the z value on which a buoy should be searched")
    method(:find_and_strafe_buoy) do
        distance = arguments[:distance]
        heading = arguments[:heading]
        speed = arguments[:speed]
        z = arguments[:z]

        half_rescue_angle = Math::PI / 2.0

        buoy = self.buoy

        buoy.script do
            setup_logger(Robot)

            data_reader 'buoy_servoing_command', ['detector', 'relative_position_command']
            data_reader 'orientation', ['control', 'orientation_with_z', 'orientation_z_samples']
            data_writer 'rel_pos_command', ['control', 'command', 'position_command']
            data_writer 'motion_command', ['control', 'controller', 'command']
         
            wait_any control_child.command_child.start_event

            execute do
                control_child.command_child.motion_command_port.disconnect_from control_child.controller_child.command_port
            end

            if !heading
                poll do
                    if o = orientation
                        heading = o.orientation.yaw
                        transition!
                    end
                end
            end

            execute do
                Robot.info "Move forward and search a buoy on the front"
            end

            poll_until detector_child.buoy_detected_event do
                motion_command.heading = heading
                motion_command.z = z
                motion_command.x_speed = speed
                motion_command.y_speed = 0
                write_motion_command
            end

            execute do
                Robot.info "Found a buoy and start servoing"
                
                auv_relpos_controller = control_child.command_child
                auv_relpos_controller.motion_command_port.connect_to control_child.controller_child.command_port
            end

            poll do
                buoy_detector = detector_child

                if buoy_detector.buoy_lost?
                    Robot.info "Buoydetector have lost a buoy in screen. Start Turning"
                    # TODO: reaction to lost buoy ... e.g. 2 * PI - Rotation while searching a buoy again
                    emit :failed
                elsif buoy_detector.strafing?
                    Robot.info "Robot start strafing around the buoy"
                elsif buoy_detector.strafe_finished?
                    Robot.info "Strafing around the buoy has been finished"
                elsif buoy_detector.strafe_error?
                    Robot.warn "Strafing failed at the buoy"
                elsif buoy_detector.moving_to_cutting_distance?
                    Robot.info "Aligning auv for perfect cutting distance"
                elsif buoy_detector.cutting?
                    Robot.info "Start moving for cutting the buoy"
                elsif buoy_detector.cutting_success?
                    Robot.info "Buoy is released from rope hopefully. Estimate successful cutting"
                    transition!
                elsif buoy_detector.cutting_error?
                    Robot.info "Something failed in cutting"
                    emit :failed
                end
            end

            emit :success
        end
    end


    # -------------------------------------------------------------------------

    # The angular tolerance around the target heading to declare that we reached
    # it. The task will require the heading to not be further away than
    # PIPELINE_HOVERING_STABILITY_THRESHOLD radians for
    # PIPELINE_HOVERING_STABILITY_TIME before declaring success
    PIPELINE_HOVERING_STABILITY_THRESHOLD = 10 * Math::PI / 180
    # The amound of seconds we require our heading to be close to target before
    # announcing a success
    PIPELINE_HOVERING_STABILITY_TIME = 10
    describe("rotate to a specific direction in focus of the end of pipeline").
        required_arg("target_yaw", "the target heading in radians")
    method(:pipeline_hovering) do
        rotation_speed = arguments[:rotation_speed]
        target_yaw     = arguments[:target_yaw]

        # we need the pipeline definition for visual servoing on the end of pipeline
        pipeline = self.pipeline
        pipeline.script do
            data_reader 'orientation', ['control', 'orientation_with_z', 'orientation_z_samples']
            data_reader 'pipeline_servoing_command', ['detector', 'relative_position_command']
            data_writer 'rel_pos_command', ['control', 'command', 'position_command']

            wait_any control_child.command_child.start_event
            execute do
                # Disconnect the pipeline detector from the AUV relpos
                # controller
                pipeline_detector_port = detector_child.relative_position_command_port
                auv_relpos_port        = control_child.command_child.position_command_port
                pipeline_detector_port.disconnect_from auv_relpos_port
            end

            stability_start = nil
            poll do
                servoing_command    = pipeline_servoing_command
                current_orientation = orientation
                if servoing_command && current_orientation
                    heading_error = target_yaw - current_orientation.orientation.yaw
                    servoing_command.heading = heading_error
                    rel_pos_command_writer.write(servoing_command)

                    if heading_error.abs < PIPELINE_HOVERING_STABILITY_THRESHOLD
                        stability_start ||= Time.now
                    else stability_start = nil
                    end

                    if stability_start && (Time.now - stability_start) > PIPELINE_HOVERING_STABILITY_TIME
                        transition!
                    end
                end
            end
            emit :success
        end
    end
    
    # -------------------------------------------------------------------------

    HEADING_ZERO_THRESHOLD = 10 * Math::PI / 180.0

    # heading or relative_heading must be given
    describe("simple rotate with a given speed for a specific angle").
        required_arg("z", "initial z value on which robot should rotate").
        optional_arg("heading", "the wanted absolute heading").
        optional_arg("relative_heading", "adding a relative heading to the current one")
    
    method(:rotate) do
        heading          = arguments[:heading]
        relative_heading = arguments[:relative_heading]
        z                = arguments[:z]

        if heading.nil? and relative_heading.nil?
            execute do 
                Robot.error "No :heading or :relative_heading is given to this method"
                emit :failed
            end
        end

        control = Cmp::ControlLoop.use('command' => AuvRelPosController::Task).as_plan

        control.script do
            data_reader 'orientation', ['orientation_with_z', 'orientation_z_samples']
            data_writer 'motion_command', ['controller', 'command']

            wait_any command_child.start_event

            execute do
                command_child.motion_command_port.disconnect_from controller_child.command_port
                Robot.info "Start rotation"
            end

            next_heading = nil

            poll do
                current_heading = orientation.orientation.yaw

                if not current_heading.nil?
                    next_heading = if not heading.nil? then heading 
                                   else current_heading + relative_heading end

                    if next_heading > Math::PI then next_heading -= (2 * Math::PI)
                    elsif next_heading < -Math::PI then next_heading += (2 * Math::PI)
                    end

                    transition!
                end
            end 

            poll do
                current_heading = orientation.orientation.yaw

                if not current_heading.nil?
                    #heading = if not heading.nil? then heading
                    #          else next_heading end

                    motion_command.x_speed = 0
                    motion_command.y_speed = 0
                    motion_command.z = z
                    motion_command.heading = next_heading
                    write_motion_command

                    heading_error = next_heading - current_heading
                    if heading_error > Math::PI then heading_error -= (2 * Math::PI)
                    elsif heading_error < -Math::PI then heading_error += (2 * Math::PI)
                    end

                    if heading_error.abs < HEADING_ZERO_THRESHOLD
                        transition!
                    end
                end
            end

            execute do
                Robot.info "Rotation finished"
            end

            emit :success
        end
    end

    # -------------------------------------------------------------------------

    # -------------------------------------------------------------------------

    describe("simple move forward with a given speed for a specific duration").
        required_arg("speed", "set the current speed of this movement").
        required_arg("duration", "set the current duration in s for the movement").
        required_arg("z", "the Z value at which we should move forward").
        required_arg("heading", "heading for the forward movement")

    method(:move_forward) do
        speed = arguments[:speed]
        duration = arguments[:duration]
        z = arguments[:z]
        heading = arguments[:heading]

        control = Cmp::ControlLoop.use('command' => AuvRelPosController::Task).as_plan

        control.script do
            setup_logger(Robot)
            
            data_reader 'orientation', ['orientation_with_z', 'orientation_z_samples']
            data_writer 'motion_command', ['controller', 'command']

            endTime = nil
            
            wait_any command_child.start_event

            if heading.respond_to?(:call)
                describe "move_forward: getting heading from block"
                execute do
                    heading = heading.call
                    Robot.info "move_forward: heading=#{heading * 180 / Math::PI}"
                end
            elsif !heading
                describe "move_forward: autodetecting heading"
                poll do
                    if o = orientation
                        heading = o.orientation.yaw
                        Robot.info "move_forward: using heading=#{heading * 180 / Math::PI}"
                        transition!
                    end
                end
            end
            
            execute do
                command_child.motion_command_port.disconnect_from controller_child.command_port
                endTime = Time.now + duration
            end
 
            poll do
                # check if the duration time elapsed and break out of the loop
                if Time.now >= endTime
                    Robot.info "move_forward: timeout reached"
                    transition!
                end

                # send movements commands to the Motion Controller
                motion_command.heading = heading
                motion_command.z = z
                motion_command.x_speed = speed
                motion_command.y_speed = 0
                write_motion_command
            end

            describe "move_forward: restoring plain connection state"
            execute do
                # Connect AUV Position Controller to the MotionControl Task
                command_child.motion_command_port.connect_to controller_child.command_port
            end

            describe "move_forward: done"
            emit :success
        end
    end

    # -------------------------------------------------------------------------
    

    RUN_IN_SIMULATION = false
    if RUN_IN_SIMULATION
        PIPELINE_SEARCH_HEADING = 0
        PIPELINE_SEARCH_SPEED = 0.1
	CHECKING_CANDIDATE_SPEED = 0.1
        PIPELINE_SEARCH_Z = -4.5
        PIPELINE_EXPECTED_HEADING = 0.0
        FIRST_GATE_HEADING = 0
        FIRST_GATE_PASSING_SPEED = 0.5 
        FIRST_GATE_PASSING_Z = PIPELINE_SEARCH_Z
        GATE_PASSING_DURATION = 5
    else
        PIPELINE_SEARCH_HEADING = 20 * Math::PI / 180
        PIPELINE_EXPECTED_HEADING = 110 * Math::PI / 180
        PIPELINE_SEARCH_SPEED = 0.7
        PIPELINE_RETURNING_SPEED = 0.3
	CHECKING_CANDIDATE_SPEED = 0.2
        PIPELINE_SEARCH_Z = -2.5
        FIRST_GATE_HEADING = PIPELINE_EXPECTED_HEADING

        FIRST_GATE_PASSING_SPEED = 0.5
        FIRST_GATE_PASSING_DURATION = 3
        FIRST_GATE_PASSING_Z = PIPELINE_SEARCH_Z

	SECOND_PIPELINE_SERVOING_ACTIVATION_THRESHOLD = 0.8

        SECOND_GATE_PASSING_SPEED = 0.5
        SECOND_GATE_PASSING_DURATION = 7
        SECOND_GATE_PASSING_Z = PIPELINE_SEARCH_Z

        FIND_BUOY_SPEED = 0.2
        FIND_BUOY_DEPTH = -2.4
        FIND_BUOY_TIMEOUT = 5
        # TODO: enter correct value for z of the red buoy
        FIND_BUOY_TURNING_Z = -4.5
        WALL_DISTANCE_THRESHOLD = 1.5
    end

    method(:sauce_pipeline) do
	find_and_follow_pipeline(:heading => PIPELINE_SEARCH_HEADING, 
			:speed => PIPELINE_SEARCH_SPEED, 
			:z => PIPELINE_SEARCH_Z,
			:expected_pipeline_heading => PIPELINE_EXPECTED_HEADING)
    end

    describe "just after the pipeline, approaches the wall using the sonar, turns towards the buoy and servoes the wall until either a buoy is detected or a timeout is found"
    method(:find_buoy) do
        main = LookForBuoy.new

        # First part: get closer to the wall, using the wall detector as a
        # distance estimator
        move = move_forward(:duration => 10,
                            :speed => FIND_BUOY_SPEED,
                            :z => FIND_BUOY_DEPTH)
        move.depends_on(wall_distance_estimator, :as => 'wall_distance')
        move.script do
            data_reader 'wall_info', ['wall_distance']
            wait_any wall_distance_child.start_event
            
            poll do
                # TODO
                # Wait for distance < threshold
                # transition!
                current_distance = wall_info.detector.distance

                if not current_distance.nil?
                    if current_distance < WALL_DISTANCE_THRESHOLD
                        transition!
                    end
                end
            end

            emit :success
        end

        # Second part: rotate towards the buoy
        turn = rotate(:relative_heading => Math::PI, :z => FIND_BUOY_TURNING_Z)

        # Third part: use the wall servoing with the wall full right. Try to get
        # a detected buoy
        main.depends_on(approach = wall_approach_buoy, :role => 'approach')
        approach.depends_on(buoy_detector = self.buoy_detector, :as => "buoy_detector")
        buoy_detector.buoy_detected_event.
            forward_to main.found_event

        # Timeout on the buoy detection
        main.script do
            wait approach_child.start_event
            start = nil
            execute do
                start = Time.now
            end
            poll do
                if Time.now - start > FIND_BUOY_TIMEOUT
                    emit :not_found
                end
            end
        end

        main.add_sequence(move, turn, approach)
        main
    end

    method(:qualif_pipeline) do
        find_pipe = sauce_pipeline
	find_pipe.on :success do |event|
            heading = event.task.detector_child.pipeline_heading
            Robot.info "storing pipeline heading: #{heading * 180 / Math::PI}deg"
	    State.pipeline_heading = heading
	end
        gate_passing = move_forward( :speed => FIRST_GATE_PASSING_SPEED,
			:z => FIRST_GATE_PASSING_Z,
			:duration => FIRST_GATE_PASSING_DURATION,
                        :heading => proc { State.pipeline_heading })
        
        # hovering = pipeline_hovering(:target_yaw => FIRST_GATE_HEADING)

        gate_returning = find_and_follow_pipeline(
            :speed => -PIPELINE_RETURNING_SPEED, 
            :z => PIPELINE_SEARCH_Z,
            :pipeline_activation_threshold => SECOND_PIPELINE_SERVOING_ACTIVATION_THRESHOLD)
        gate_returning.on :success do |event|
            heading = event.task.detector_child.pipeline_heading
            Robot.info "storing pipeline heading: #{heading * 180 / Math::PI}deg"
            State.pipeline_heading = heading
        end
        
        second_gate_passing = move_forward(
            :speed => SECOND_GATE_PASSING_SPEED,
            :z => SECOND_GATE_PASSING_Z,
            :duration => SECOND_GATE_PASSING_DURATION,
            :heading => proc { State.pipeline_heading })

        task = SaucE.new
        task.add_sequence(find_pipe, gate_passing, gate_returning, second_gate_passing)
        second_gate_passing.success_event.forward_to task.success_event
        task
    end

    method(:qualif_wall) do
        wall_left
    end

    # starting point for testing pipeline following
    #  sim_set_position 15, -5, -4.5
    describe("Autonomous run for running all sauce-specific tasks")
    method(:autonomous_run) do
        find_pipe = sauce_pipeline
	find_pipe.on :success do |event|
            heading = event.task.detector_child.pipeline_heading
            Robot.info "storing pipeline heading: #{heading * 180 / Math::PI}deg"
	    State.pipeline_heading = heading
	end
        gate_passing = move_forward( :speed => FIRST_GATE_PASSING_SPEED,
			:z => FIRST_GATE_PASSING_Z,
			:duration => FIRST_GATE_PASSING_DURATION,
                        :heading => proc { State.pipeline_heading })
        
        # hovering = pipeline_hovering(:target_yaw => FIRST_GATE_HEADING)

        gate_returning = find_and_follow_pipeline(
            :speed => -PIPELINE_RETURNING_SPEED, 
            :z => PIPELINE_SEARCH_Z,
            :pipeline_activation_threshold => SECOND_PIPELINE_SERVOING_ACTIVATION_THRESHOLD)
        gate_returning.on :success do |event|
            heading = event.task.detector_child.pipeline_heading
            Robot.info "storing pipeline heading: #{heading * 180 / Math::PI}deg"
            State.pipeline_heading = heading
        end
        
        second_gate_passing = move_forward(
            :speed => SECOND_GATE_PASSING_SPEED,
            :z => SECOND_GATE_PASSING_Z,
            :duration => SECOND_GATE_PASSING_DURATION,
            :heading => proc { State.pipeline_heading })
        wall_servoing = wall_left

        task = SaucE.new
        task.add_sequence(find_pipe, gate_passing, gate_returning, second_gate_passing, wall_servoing)
        task
    end

    # -------------------------------------------------------------------------
end

class Roby::Task
    def add_sequence(*tasks)
        last_task = nil
        tasks.each do |t|
            depends_on t
            if last_task
                t.should_start_after last_task
            end
            last_task = t
        end
    end
end

# Other operations
#
#     wait detector_child.follow_pipe_event
#
#     poll do
#        if <condition>
#          transition!
#        end
#     end
#
#     poll do
#       if <condition>
#         # delayed transition
#         transition!(20)
#       end
#     end
#
#     emit <event>
#       emits the event on the task
