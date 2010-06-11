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

    connect imu.orientation_samples => estimator.orientation_samples
    autoconnect
end

