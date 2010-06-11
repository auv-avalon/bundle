import_types_from 'base'

data_service 'ImageSource' do
    output_port 'frame', '/RTT/ReadOnlyPointer</base/samples/frame/Frame>'
end

data_service 'LaserImagePairSource' do
    output_port 'laser_frame_pair', '/RTT/ReadOnlyPointer</base/samples/frame/FramePair>'
end

data_service 'Detector'

#### TAKEN FROM IMOBY -- DO NOT CHANGE
## Interfaces for pose estimation
data_service_type 'Depth' do
    output_port 'depth_samples', '/wrappers/samples/RigidBodyState'
end
data_service_type 'Position' do
    output_port 'position_samples', '/wrappers/samples/RigidBodyState'
end

data_service_type 'Pose' do
    output_port 'pose_samples', '/wrappers/samples/RigidBodyState'
end

data_service_type 'Orientation' do
    output_port 'orientation_samples', '/wrappers/samples/RigidBodyState'
end

data_service_type 'IMUSensors'
data_service_type 'CompensatedIMUSensors', :child_of => IMUSensors do
    output_port 'compensated_sensors', '/wrappers/samples/IMUSensors'
end

data_service_type 'CalibratedIMUSensors', :child_of => IMUSensors do
    output_port 'calibrated_sensors', '/wrappers/samples/IMUSensors'
end

