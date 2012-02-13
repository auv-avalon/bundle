# The main planner. A planner of this model is automatically added in the
# Interface planner list.
class MainPlanner < Roby::Planning::Planner
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
        stabilization_time = arguments[:stabilization_time] || PIPELINE_STABILIZATION_TIME

        # Get a task representing the define('pipeline')
        pipeline = self.pipeline

        # Get (orocos) task context of pipeline detector
        #pipeline_detector_task = pipeline.detector_child

        # Set default speed
        #pipeline_detector_task.orogen_task.default_x = speed
        #
        checking_candidate_speed =
            if speed > 0 then PIPELINE_SEARCH_CANDIDATE_SPEED
            else -PIPELINE_SEARCH_CANDIDATE_SPEED
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
            #
            removed_connections = nil
            with_description "starting find_and_follow_pipeline" do
                wait_any detector_child.start_event
                wait_any control_child.command_child.start_event
                execute do
                    removed_connections = control_child.command_child.disconnect_ports(control_child.controller_child, [['motion_command', 'command']])
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
            poll do
                motion_command.heading = heading
                motion_command.z = z
                motion_command.y_speed = 0

                last_event = detector_child.history.last
                if last_event.symbol == :check_candidate
                    motion_command.x_speed = checking_candidate_speed
                elsif detector_child.found_pipe?
                    transition!
                else
                    Robot.info "normal search"
                    motion_command.x_speed = speed
                end
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
                control_child.command_child.connect_ports(control_child.controller_child, removed_connections)
                Robot.info "Robot is aligning. Wait until done."
            end
            wait detector_child.follow_pipe_event

            describe "find_and_follow_pipeline: following the pipe until end_of_pipe"
            wait detector_child.end_of_pipe_event

            describe "find_and_follow_pipeline: pipeline end reached, waiting #{PIPELINE_STABILIZATION_TIME} seconds for stability"
            wait stabilization_time

            describe "find_and_follow_pipeline: finished"
            emit :success
        end
    end

    # -------------------------------------------------------------------------

    BUOY_SERVOING_VALIDATION_WINDOW = 500
    BUOY_SERVOING_DISTANCE = 2
    describe("move forward as long as a buoy is found by the detector and start
              servoing and later strafing around the buoy").
        required_arg("heading", "initial heading where search a buoy").
        required_arg("speed", "forward speed for searching a buoy").
        required_arg("z", "the z value on which a buoy should be searched")
    method(:find_and_servo_buoy) do
        heading = arguments[:heading]
        speed   = arguments[:speed]
        z       = arguments[:z]
        search_timeout = arguments[:search_timeout]

        buoy = self.buoy
        # Guard for finding / maintaining the buoy
        buoy.script do
            data_reader 'detected_buoy', ['detector', 'detector', 'buoy']
            timeout search_timeout, :emit => :failed_to_find_buoy do
                wait detector_child.buoy_detected_event
            end

            if BUOY_HAS_STRAFE_STATE
                timeout BUOY_DETECTION_TO_STRAFE_TIMEOUT, :emit => :failed_to_approach do
                    wait detector_child.buoy_arrived_event
                    wait detector_child.strafe_start_event
                end

                timeout BUOY_STRAFE_TO_CUT_TIMEOUT, :emit => :failed_to_strafe do
                    wait detector_child.cutting_event
                end
            else
                timeout BUOY_DETECTION_TO_STRAFE_TIMEOUT, :emit => :failed_to_approach do
                    wait detector_child.buoy_arrived_event
                end
                timeout BUOY_DETECTION_TO_STRAFE_TIMEOUT + BUOY_STRAFE_TO_CUT_TIMEOUT, :emit => :failed_to_strafe do
                    wait detector_child.cutting_event
                end
            end

            timeout BUOY_CUTTING_TIMEOUT, :emit => :failed_to_cut do
                wait detector_child.cutting_success_event
            end


            # window = []
            # poll_until detector_child.cutting_event do
            #     if (b = detected_buoy)
            #         window.unshift(b.world_coord.x)

            #         actual_window = window.find_all { |x| x != 0 }
            #         if actual_window.size > BUOY_SERVOING_VALIDATION_WINDOW
            #             window.pop
            #             mean1 = actual_window[0, BUOY_SERVOING_VALIDATION_WINDOW / 2].inject(&:+) / window.size / 2
            #             mean0 = actual_window[BUOY_SERVOING_VALIDATION_WINDOW / 2, BUOY_SERVOING_VALIDATION_WINDOW / 2].inject(&:+) / window.size / 2

            #             # Error if we are too far away from the buoy and don't
            #             # get nearer
            #             if (mean1 + mean0) / 2 > 2 * BUOY_SERVOING_DISTANCE && (mean1 - mean0) / mean0 > -0.1
            #                 emit :failed_to_approach
            #             end
            #         end
            #     end
            # end
        end
        # Guard for lost buoy (no support for this kind of timeout yet ...)
        buoy.script do
            wait detector_child.buoy_detected_event

            start_time = Time.now
            poll do
                last_ev = detector_child.history.last
                if last_ev.symbol == :buoy_lost
                    emit :buoy_lost
                    if start_time && (Time.now - start_time) > BUOY_LOST_TIMEOUT
                        emit :buoy_lost
                    else
                        start_time = last_ev.time
                    end
                else
                    start_time = nil
                end
            end
        end
        # Main script: find, servo and cut
        buoy.script do
            setup_logger(Robot)

            data_reader 'orientation', ['control', 'orientation_with_z', 'orientation_z_samples']
            data_writer 'motion_command', ['control', 'controller', 'command']
         
            wait_any detector_child.detector_child.start_event
            wait_any control_child.command_child.start_event

            removed_connections = nil
            execute do
                removed_connections = control_child.command_child.
                    disconnect_ports(control_child.controller_child, [['motion_command', 'command']])

                buoydetector = detector_child.detector_child
                buoydetector.orogen_task.run_in_simulation = IS_SIMULATION
                buoydetector.orogen_task.debug_gui = false
                buoydetector.orogen_task.buoy_depth = z
            end

            if heading.respond_to?(:call)
                execute { heading = heading.call }
            elsif !heading
                poll do
                    if o = orientation
                        heading = o.orientation.yaw
                        transition!
                    end
                end
            end

            execute do
                Robot.info "starting to dive. Heading=#{heading * 180 / Math::PI}"
            end

            poll do
                motion_command.heading = heading
                motion_command.z = z
                motion_command.x_speed = 0
                motion_command.y_speed = 0
                write_motion_command

                if o = orientation
                    if o.position.z < FIND_BUOY_MIN_Z
                        transition!
                    end
                end
            end

            execute do
                Robot.info "looking for a buoy ..."
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
                control_child.command_child.
                    connect_ports(control_child.controller_child, removed_connections)
            end

            wait detector_child.cutting_success_event
            execute do
                Robot.info "buoy cutted"
            end
            emit :success
        end
    end


    # -------------------------------------------------------------------------

    # heading or relative_heading must be given
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
            data_writer 'motion_command', ['controller', 'command']

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

                command_child.disconnect_ports(controller_child, [['motion_command', 'command']])
                Robot.info "start simple_move at target_heading=#{target_heading} and z=#{z}"
                Robot.info " going to target with speed=#{descent_speed}"
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

                    if heading_error.abs < SIMPLE_MOVE_HEADING_THRESHOLD && depth_error.abs < SIMPLE_MOVE_Z_THRESHOLD
                        transition!
                    end
                end
            end

            execute do
                Robot.info "reached specified station keeping position"
            end
            if duration
                execute do
                    Robot.info " waiting #{duration} with speed=#{wait_speed}"
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

    # Helper method to deal with all the possible configurations of the wall
    # servoing
    #
    # +name+ is the definition of the wall servoing composition we should run
    def wall_servoing(name)
        task = send(name)
        task.script do
            timeout WALL_SEARCH_TIMEOUT, :emit => :failed do
                wait detector_child.found_wall_event
            end
            timeout WALL_CORNER_TIMEOUT, :emit => :failed do
                wait detector_child.corner_passed_event
            end
            wait WALL_SUCCESS_TIMEOUT_AFTER_CORNER
            emit :success_event
        end
        task
    end
end

class Roby::Task
    def add_sequence(*tasks)
        last_task = nil
        tasks.each do |t|
            depends_on t
            if last_task
                t.should_start_after last_task.success_event
            end
            last_task = t
        end
    end
end

def normalize_angle(angle)
    if angle > Math::PI
        angle - 2*Math::PI
    elsif angle < -Math::PI
        angle + 2*Math::PI
    else angle
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
