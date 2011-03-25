import_types_from 'base'

####################################
## Control related services

data_service_type 'Actuators' do
    input_port("command", "base/actuators/Command")
#    output_port("status", "base/actuators/Status")
end

data_service_type 'FourWheelPlatform' do
    provides Srv::Actuators
end

# Base interfaces for control
data_service_type 'ActuatorController' do
    output_port("actuator_command", "base/actuators/Command").
      doc("Actuator command")
end

data_service_type 'Command'

# This is separated from Controller as other type of control exist in the
# components (as for instance FourWheelController in controldev)
data_service_type 'Motion2DController' do
    provides Srv::ActuatorController
    input_port('command', 'base/MotionCommand2D').
        doc('input command in rotation and translation.')
end

data_service_type 'Motion2DCommand' do
    provides Srv::Command
    output_port 'command', 'base/MotionCommand2D'
end

# This is separated from Controller as other type of control exist in the
# components (as for instance FourWheelController in controldev)
data_service_type 'AUVMotionController' do
    provides Srv::ActuatorController
    input_port('command', 'base/AUVMotionCommand').
        doc('input command in rotation and translation.')
end

data_service_type 'AUVMotionCommand' do
    provides Srv::Command
    output_port 'command', 'base/AUVMotionCommand'
end

####################################
## Services related to pose estimation

data_service_type 'Position' do
    output_port 'position_samples', '/base/samples/RigidBodyState'
end

data_service_type 'Orientation' do
    output_port 'orientation_samples', '/base/samples/RigidBodyState'
end

data_service_type 'Pose' do
    output_port 'pose_samples', '/base/samples/RigidBodyState'
    provides Srv::Position,    'position_samples' => 'pose_samples'
    provides Srv::Orientation, 'orientation_samples' => 'pose_samples'
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

data_service_type 'StereoPairProvider' do
    output_port 'images', ro_ptr('/base/samples/frame/FramePair')
end

data_service_type 'LaserRangeFinder' do
    output_port 'scans', '/base/samples/LaserScan'
end

