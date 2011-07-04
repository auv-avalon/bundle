# The main planner. A planner of this model is automatically added in the
# Interface planner list.
class MainPlanner < Roby::Planning::Planner
    GATE_TURN_DIRECTION = 1
    CHECKING_CANDIDATE_SPEED = 0.1
    STOPPING_DURATION = 4 # Seconds needed to stop the vehicle from max speed

    describe("moves forward and turns on pipeline following if a pipeline is detected").
        required_arg("z", "the Z value at which we should search for the pipeline").
        required_arg("speed", "the forward speed at which we should search for the pipeline")
    method(:find_and_follow_pipeline) do
        z     = arguments[:z]
        speed = arguments[:speed]

        # Get a task representing the define('pipeline')
        pipeline = self.pipeline

        # Get (orocos) task context of pipeline detector
        #pipeline_detector_task = pipeline.detector_child

        # Set default speed
        #pipeline_detector_task.orogen_task.default_x = speed

        # Code the actual actions
        pipeline.script do
            setup_logger(Robot)

            # Define a 'orientation_reader' and 'orientation' methods that allow
            # access to control.pose.orientation_z_samples
            data_reader 'orientation', ['control', 'orientation_with_z', 'orientation_z_samples']
            data_reader 'pipeline_servoing_command', ['detector', 'relative_position_command']

            # Define 'motion_command_writer', 'motion_command' and 'write_motion_command'
            data_writer 'motion_command', ['control', 'controller', 'command']
            data_writer 'rel_pos_command', ['control', 'command', 'position_command']

            # <blabla>_child
            #    returns the child named 'blabla' from the receiver
            #
            #    i.e. control_child => returns the Cmp::ControlLoop
            #         control_child.command_child => returns  the AUVMotionController
            #
            # <blabla>_port
            #    returns the port named 'blabla' from the receiver
            #         control_child.command_child.motion_command_port => returns motion_command_port from the AUVMotionController

            execute do
                control_child.command_child.motion_command_port.disconnect_from control_child.controller_child.command_port
            end

            poll do
                if orientation
                    motion_command.heading = orientation.orientation.yaw
                    transition!
                end
            end

            poll_until detector_child.check_candidate_event do
              motion_command.z = z
              motion_command.x_speed = speed
              motion_command.y_speed = 0
              write_motion_command
            end

            Robot.info "Slow AUV down for checking candidates on pipeline detection"

            poll_until detector_child.align_auv_event do
              motion_command.x_speed = CHECKING_CANDIDATE_SPEED
              write_motion_command
            end

            execute do
                Robot.info "Now visual servoing for pipeline"
                control_child.command_child.motion_command_port.connect_to control_child.controller_child.command_port
                Robot.info "Robot is aligning. Wait until done."
            end

            wait detector_child.follow_pipe_event

            execute do
                Robot.info "Following the pipe."
            end

            wait detector_child.end_of_pipe_event

            execute do
                Robot.info "Pipeline end reached."
            end

            # Stop after end of pipeline. Hold heading 0 (-> debug).
            poll do
              motion_command.z = z
              motion_command.x_speed = 0
              motion_command.y_speed = 0
              motion_command.heading = 0
              write_motion_command
            end


            execute do
                Robot.info "Pipeline Servoing completed!"
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

            wait control_child.command_child.start_event
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

    describe("simple rotate with a given speed for a specific angle").

        required_arg("speed", "set the current rotation speed").
        required_arg("angle", "set the angle of rotate")

    method(:rotate) do
        speed = arguments[:speed]
        angle = arguments[:angle]

        control = Cmp::ControlLoop.use(AuvRelPosController::Task).as_plan
        # control.depends_on(Srv::Orientation)

        control.script do
            # TODO: get control ports and rotate
            data_writer 'motion_command', ['controller', 'command']

            execute do
            end
        end
    end


    # -------------------------------------------------------------------------

    describe("simple move forward with a given speed for a specific duration").
        required_arg("speed", "set the current speed of this movement").
        required_arg("duration", "set the current duration in s for the movement").
        required_arg("z", "the Z value at which we should move forward")

    method(:move_forward) do
        speed = arguments[:speed]
        duration = arguments[:duration]
        z = arguments[:z]

        control = Cmp::ControlLoop.use('command' => AuvRelPosController::Task).as_plan

        control.script do
            # Define 'motion_command_writer', 'motion_command' and 'write_motion_command'
            data_writer 'motion_command', ['controller', 'command']

            # Determine end time of moving forward
            endTime = Time.now + duration

            poll do
                if(Time.now >= endTime)
                    transition!
                end
                motion_command.z = z
                motion_command.x_speed = speed
                motion_command.y_speed = 0
                write_motion_command
            end

            # Stop the vehicle
            endTime = Time.now + STOPPING_DURATION
            poll do
                if(Time.now >= endTime)
                    transition!
                end
                motion_command.z = z
                motion_command.x_speed = speed
                motion_command.y_speed = 0
                write_motion_command
            end

            emit :success

        end
    end

   # -------------------------------------------------------------------------
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
