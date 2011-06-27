# The main planner. A planner of this model is automatically added in the
# Interface planner list.
class MainPlanner < Roby::Planning::Planner
    describe("moves forward and turns on pipeline following if a pipeline is detected").
        required_arg("z", "the Z value at which we should search for the pipeline").
        required_arg("speed", "the forward speed at which we should search for the pipeline")

    GATE_TURN_DIRECTION = 1

    CHECKING_CANDIDATE_SPEED = 0.1

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
