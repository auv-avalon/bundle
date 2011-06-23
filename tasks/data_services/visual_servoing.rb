load_system_model 'tasks/data_services/control'

data_service_type 'RelativePositionDetector' do
    provides Srv::RelativePositionCommand
end

