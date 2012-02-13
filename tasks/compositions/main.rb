# This is separated from Controller as other type of control exist in the
# components (as for instance FourWheelController in controldev)

load_system_model 'tasks/data_services/visual_servoing'

composition 'ControlLoop' do
    abstract

    def self.controller_type(name, command_type, &block)
        controller = system_model.data_service_type "#{name}Controller" do
            provides Srv::ActuatorController
            input_port 'command', command_type
        end

        command = system_model.data_service_type "#{name}Command" do
            provides Srv::Command
            output_port 'command', command_type
        end

        specialize 'controller' => controller, 'command' => command do
            instance_eval(&block) if block
            autoconnect
        end
        return controller, command
    end

    add Srv::Actuators
    add Srv::ActuatorController, :as => 'controller'
    add Srv::Command, :as => 'command'

    autoconnect
end

Cmp::ControlLoop.controller_type 'Motion2D', '/base/MotionCommand2D'
Cmp::ControlLoop.controller_type 'AUVMotion', '/base/AUVMotionCommand'

using_task_library 'auv_rel_pos_controller'
using_task_library 'avalon_control'
using_task_library 'hbridge'

composition 'VisualServoing' do
    add Srv::RelativePositionDetector, :as => 'detector'
    add(Cmp::ControlLoop, :as => 'control').
      use('command' => AuvRelPosController::Task)

    autoconnect
end

# NOTE: the 'controller' => Bla part of the specialization should not be needed,
# but is as of today (29.05.2011)
Cmp::ControlLoop.specialize 'command' => AuvRelPosController::Task do
#    add Srv::OrientationWithZ

    overload 'controller', Srv::AUVMotionController
    #connect command.motion_command => controller.command
    export command.position_command
    
    autoconnect
end

Cmp::ControlLoop.specialize 'controller' => AvalonControl::MotionControlTask do
    add Srv::OrientationWithZ, :as => 'pose'
    connect pose.orientation_z_samples => controller.pose_samples
end

Cmp::ControlLoop.specialize 'controller' => AvalonControl::PositionControlTask do
    add Srv::Pose
    autoconnect
end

require 'roby/tasks/timeout'
Compositions::ControlLoop.specialize 'actuators' => Hbridge::Task do
    add Hbridge::Task, :as => 'actuators',
        :consider_in_pending => false,
        :failure => [:read_only.not_followed_by(:read_write), :stop]

    on :start do |ev|
        hbridge = child_from_role 'actuators'

        # When we start the control composition, disable error handling for the
        # hbridge for 10 seconds in order to wait for it to do its calibration
        # and/or simply the read_only to read_write switch
        timeout = Roby::Tasks::Timeout.new(:delay => 10)
        timeout.on(:start) { |ev| Robot.info "delaying read_only errors by #{timeout.delay} seconds" }
        timeout.on(:timed_out)  { |ev| Robot.info "timed out on read_only to read_write switch, resuming handling of hbridge errors" }
        hbridge.read_only_event.handle_with(timeout)
        timeout.start!

      Robot.info "hb is of class #{hbridge.class}"

        Robot.info  "timout started"
        # But resume error handling as soon as read_write is emitted
        hbridge.read_write_event.on do |event|
            Robot.info "Event: #{event} is calles"
            Robot.info "hbridge switched to read_write, resuming handling of hbridge errors"
        end
        hbridge.read_write_event.signals timeout.stop_event
    end
end
