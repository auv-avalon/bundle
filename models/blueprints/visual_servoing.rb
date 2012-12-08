load_system_model 'blueprints/control'

data_service_type 'RelativePositionDetector' do
    provides Srv::RelativePositionCommand
end

