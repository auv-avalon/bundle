include Orocos

# The main planner. A planner of this model is automatically added in the
# Interface planner list.
class MainPlanner < Roby::Planning::Planner
    GATE_TURN_DIRECTION = 1
    CHECKING_CANDIDATE_SPEED = 0.1

    describe("test the altitude mode of the pipeline detector.").
        required_arg("z", "the Z value at which we _cshould search for the pipeline").
        required_arg("speed", "the forward speed at which we should search for the pipeline")
    method(:pipeline_test_altitude) do
        z     = arguments[:z]
        speed = arguments[:speed]

        # Get a task representing the define('pipeline')
        pipeline = self.pipeline # Cmp::VisualServoing.  use(Cmp::PipelineDetector.use('bottom_camera')).as_plan

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
            data_writer 'altitude_samples', ['detector','offshorePipelineDetector','altitude_samples']

            #disconnect detector from controler
            execute do
                control_child.command_child.motion_command_port.disconnect_from control_child.controller_child.command_port

                Roby.every(1) do
                    Typelib.copy(altitude_samples, orientation)
                    altitude_samples.position.z = 6.0 + orientation.position.z
                    puts altitude_samples.position.z
                    write_altitude_samples
                end
            end

            #wait until we have the orientation 
            poll do
                if orientation
                    motion_command.heading = orientation.orientation.yaw
                    transition!
                end
            end

            #go forward until we found a candidate
            poll_until detector_child.check_candidate_event do
              motion_command.z = z
              motion_command.x_speed = speed
              motion_command.y_speed = 0
              write_motion_command
            end

            #go slow until a pipe is found 
            poll_until detector_child.found_pipe_event do
              motion_command.x_speed = CHECKING_CANDIDATE_SPEED
              motion_command.z = z
              motion_command.y_speed = 0
              write_motion_command
            end

            #reconnect detector to the controler
            execute do
                Robot.info "Now visual servoing for pipeline"
                control_child.command_child.motion_command_port.connect_to control_child.controller_child.command_port
                Robot.info "Robot is aligning. Wait until done."
            end

            poll_until detector_child.end_of_pipe_event do
            end

            #set prefered_heading to test turning on the spot
            execute do
                detector_child.offshorePipelineDetector_child.orogen_task.prefered_heading = Math::PI
            end

            # Stop after end of pipeline. Hold heading 0 (-> debug).
            poll do
              motion_command.z = z
              motion_command.x_speed = 0
              motion_command.y_speed = 0
            #  motion_command.heading = 0
            #  write_motion_command
            end

            emit :success
        end
    end
end
