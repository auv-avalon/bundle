using_task_library 'ifg'

class StateEstimator::Task
    provides Pose
end

Compositions::PoseEstimator.specialize 'estimator', StateEstimator::Task do
    imu_sensors = add CompensatedIMUSensors, :as => 'rawImu'
    fog   = add Ifg::Task, :as => 'fog'
    imu   = add Orientation, :as => 'imu'
    depth = add Depth, :as => 'depth'

    estimator = self['estimator']

    connect fog.rotation => estimator.fog_samples,
    	:type => :buffer, :size => 20
    connect imu.orientation_samples => estimator.orientation_samples,
    	:type => :buffer, :size => 20
    connect imu_sensors.compensated_sensors => estimator.imu_sensor_samples,
    	:type => :buffer, :size => 20
    connect depth.depth_samples => estimator.depth_samples,
    	:type => :buffer, :size => 20
end

