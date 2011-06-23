load_system_model 'tasks/data_services/base'

device_type 'Camera' do
  provides Srv::ImageProvider
end

device_type 'Imu' do
  provides Srv::Pose
end
