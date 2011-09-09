import_types_from 'base'

####################################
## Services related to pose estimation

data_service_type 'Position' do
    output_port 'position_samples', '/base/samples/RigidBodyState'
end

data_service_type 'Orientation' do
    output_port 'orientation_samples', '/base/samples/RigidBodyState'
end

# This service is mainly used in underwater system, where measuring depth alone
# is easily done, while measuring a full position is pretty hard. On ground
# systems, measuring Z and position are usually done together.
data_service_type 'ZProvider' do
    output_port 'z_samples', '/base/samples/RigidBodyState'
end

# See comment on top of ZProvider
#
# Orientation and depth are values that are easy to measure in underwater
# systems, that's why we define this service
data_service_type 'OrientationWithZ' do
    output_port 'orientation_z_samples', '/base/samples/RigidBodyState'
    provides Srv::Orientation, 'orientation_samples' => 'orientation_z_samples'
    provides Srv::ZProvider, 'z_samples' => 'orientation_z_samples'
end

data_service_type 'Pose' do
    output_port 'pose_samples', '/base/samples/RigidBodyState'
    provides Srv::Position,    'position_samples' => 'pose_samples'
    provides Srv::Orientation, 'orientation_samples' => 'pose_samples'
    provides Srv::OrientationWithZ, 'orientation_z_samples' => 'pose_samples'
    provides Srv::ZProvider, 'z_samples' => 'pose_samples'
end

# This data service can be used to represent estimators that provide a pose that
# is a best estimate of the global pose of the system. Because it is a best
# estimate, it can actually jump
#
# It is typically a pose estimator which fuses a global position measurement
# such as GPS
data_service_type 'GlobalPose' do
    provides Srv::Pose
end

# This data service can be used to represent pose estimators that provide a pose
# which is locally consistent, but that will stray away from the true global
# pose in the long run. These estimators should not jump, as it would break the
# local consistency constraint
#
# It is typically an odometry
data_service_type 'RelativePose' do
    provides Srv::Pose
end

# This data service provides deltas in pose (i.e. pose change between two time
# steps). it has to be of the RelativePose type, be consistent locally
data_service_type 'PoseDelta' do
    output_port 'pose_delta_samples', '/base/samples/RigidBodyState'
end

####################################
## Sensors

data_service_type 'IMUSensors' do
    output_port 'sensors', '/base/samples/IMUSensors'
end

data_service_type 'CompensatedIMUSensors' do
    provides Srv::IMUSensors
end

data_service_type 'CalibratedIMUSensors' do
    provides Srv::IMUSensors
end

data_service_type 'ImageProvider' do
    output_port 'images', ro_ptr('/base/samples/frame/Frame')
end

data_service_type 'SonarImage' do
    output_port 'images', ro_ptr('/base/samples/frame/Frame')
end

data_service_type 'StructuredLightPair' do 
    output_port 'images', ro_ptr('/base/samples/frame/FramePair')
end

data_service_type 'StereoPairProvider' do
    output_port 'images', ro_ptr('/base/samples/frame/FramePair')
end

data_service_type 'LaserRangeFinder' do
    output_port 'laserscan', '/base/samples/LaserScan'
end

data_service_type 'SonarScanProvider' do
    output_port 'sonarscan', '/base/samples/SonarScan'
end

