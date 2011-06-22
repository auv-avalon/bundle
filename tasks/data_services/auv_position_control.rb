load_system_model 'tasks/data_services/base'

data_service_type 'OrientationWithZ' do
    output_port 'orientation_z_samples', '/base/samples/RigidBodyState'
    provides Srv::Orientation, 'orientation_samples' => 'orientation_z_samples'
end

Srv::Pose.provides Srv::OrientationWithZ, 'orientation_z_samples' => 'pose_samples'

data_service_type 'AUVRelativePositionCommand' do
    provides Srv::Command
    # In a relative position control setup, the input to the controller is the
    # error to zero
    output_port 'error', "/base/AUVPositionCommand"
end
data_service_type 'AUVAbsolutePositionCommand' do
    provides Srv::Command
    # In an absolute position control setup, the input to the controller is the
    # actual set point
    output_port 'command', "/base/AUVPositionCommand"
end

