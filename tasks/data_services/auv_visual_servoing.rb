load_system_model 'tasks/data_services/auv_position_control'

data_service_type 'VisualServoingDetector'
data_service_type 'RelativePositionDetector' do
    provides Srv::VisualServoingDetector
    provides Srv::AUVRelativePositionCommand
end
data_service_type 'ObjectPointDetector' do
    provides Srv::VisualServoingDetector
    output_port 'object_point', '/base/Vector3d'
end

composition 'VisualServoing' do
    add Srv::VisualServoingDetector, :as => 'detector'
    add Cmp::ControlLoop, :as => 'control'
end

using_task_library 'auv_rel_pos_controller'
using_task_library 'object_servoing'

Cmp::VisualServoing.specialize 'detector' => Srv::RelativePositionDetector do
    overload('control', Cmp::ControlLoop).
        use(AuvRelPosController::Task)

    autoconnect
end

Cmp::VisualServoing.specialize 'detector' => Srv::ObjectPointDetector do
    add ObjectServoing::Task, :as => "servoing"
    overload('control', Cmp::ControlLoop).
        use(AuvRelPosController::Task)

    autoconnect
end


