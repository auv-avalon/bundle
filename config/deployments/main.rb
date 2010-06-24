# Create the pose estimator and define it as being the default for pose
# estimation
pose_estimator = add(PoseEstimator).
    use 'estimator' => StateEstimator::Task,
        'imu' => DfkiImu::Task
use Pose => pose_estimator

Roby.app.orocos_engine.robot.devices.each_key do |name|
    add_mission(name)
end

# Create the demultiplexer for the front camera
add(LaserImageDemultiplexer, :as => 'front_image_acquisition').
    use 'front_camera'

# Define servoing deployments
define('pipeline_following', AUVControlLoop).
    use PipelineFollower::Task, 'bottom_camera'

modality_selection AUVControlLoop, 'pipeline_following'
