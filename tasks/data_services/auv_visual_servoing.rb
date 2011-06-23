load_system_model 'tasks/data_services/control'

data_service_type 'VisualServoingDetector'
data_service_type 'RelativePositionDetector' do
    provides Srv::VisualServoingDetector
    provides Srv::RelativePositionCommand
end

data_service_type 'ObjectPointDetector' do
    provides Srv::VisualServoingDetector
    output_port 'object_point', '/base/Vector3d'
end


