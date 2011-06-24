#Anything shared by the robot and the simulator

# use DataServices::OrientationWithZ => Cmp::OrientationEstimator

#define('wall', Cmp::VisualServoing).
#    use Cmp::WallDetector, "sonar

define('testing', Cmp::ControlLoop).
  use(AuvRelPosController::Task)

define('pipeline', Cmp::VisualServoing.
  use(Cmp::PipelineDetector.use('bottom_camera')))

define('buoy', Cmp::VisualServoing.
  use(Cmp::BuoyDetector.use('front_camera')))
