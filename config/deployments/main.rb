#Anything shared by the robot and the simulator

use DataServices::OrientationWithZ => Cmp::OrientationEstimator

define('wall', Cmp::VisualServoing).
    use Cmp::WallDetector, "sonar"

define('pipeline', Cmp::VisualServoing).
    use Cmp::PipelineDetector.use('bottom_camera')
