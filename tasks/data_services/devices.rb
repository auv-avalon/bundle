load_system_model 'tasks/data_services/base'

device_type 'Camera' do
  provides Srv::ImageProvider
end

device_type 'SimulatedMotionActuator' do
  provides Srv::MotionController
end
