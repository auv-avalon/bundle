# This is separated from Controller as other type of control exist in the
# components (as for instance FourWheelController in controldev)

load_system_model 'blueprints/visual_servoing'

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
using_task_library 'auv_waypoint_navigator'
using_task_library 'avalon_control'



composition 'VisualServoing' do
    add Srv::RelativePositionDetector, :as => 'detector'
    add(Cmp::ControlLoop, :as => 'control').
      use('command' => AuvRelPosController::Task).
      use('controller' => AvalonControl::MotionControlTask) 

    autoconnect
end


