# Create the pose estimator and define it as being the default for pose
# estimation
pose_estimator = add(PoseEstimator).
    use 'estimator' => StateEstimator::Task,
        'imu' => DfkiImu::Task
use Pose => pose_estimator

# Create the demultiplexer for the front camera
add(LaserImageDemultiplexer, :as => 'front_image_acquisition').
    use 'multiplexed_images' => 'front_camera'

# Define servoing deployments
define('pipeline_following', AUVControlLoop).
    use PipelineFollower::Task, 'front_image_acquisition'
