load_system_model 'blueprints/control'

Cmp::ControlLoop.declare 'AUVMotion', '/base/AUVMotionCommand'


data_service_type 'ZProvider' do
	output_port 'z_samples', '/base/samples/RigidBodyState'
end


data_service_type 'ModemConnection' do
	input_port 'white_light', 'bool'
        input_port 'position', '/base/samples/RigidBodyState'
	output_port 'motion_command', '/base/AUVMotionCommand'
end


data_service_type 'OrientationWithZ' do
    output_port 'orientation_z_samples', '/base/samples/RigidBodyState'
    provides Srv::Orientation, 'orientation_samples' => 'orientation_z_samples'
    provides Srv::ZProvider, 'z_samples' => 'orientation_z_samples'
end

#Prodived ground distance
data_service_type 'GroundDistance' do
    output_port 'distance', '/base/samples/RigidBodyState'
end

data_service_type 'SonarScanProvider' do
    output_port 'sonarscan', '/base/samples/SonarBeam'
end

data_service_type 'SoundSourceDirection' do
    output_port 'angle', '/base/Angle'
end

data_service_type 'StructuredLightPair' do
    output_port 'images', ro_ptr('/base/samples/frame/FramePair')
end

data_service_type 'LaserScanProvider' do
    output_port 'laserscan', '/base/samples/LaserScan'
end

data_service_type 'Speed' do
    output_port 'speed_samples', '/base/samples/RigidBodyState'
end

#data_service_type 'Position' do
#    output_port 'position_samples', '/base/samples/RigidBodyState'
#end

#data_service_type 'Orientation' do
#    output_port 'orientation_samples', '/base/samples/RigidBodyState'
#end

