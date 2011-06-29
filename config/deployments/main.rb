#Anything shared by the robot and the simulator

define('testing', Cmp::ControlLoop).
  use(AuvRelPosController::Task)

define('drive_simple', Cmp::ControlLoop).
  use(Cmp::AUVJoystickCommand)

define('pipeline', Cmp::VisualServoing.use(Cmp::PipelineDetector.use('bottom_camera')))
define('pipeline_detector', Cmp::PipelineDetector.use('bottom_camera'))

define('buoy', Cmp::VisualServoing.use(Cmp::BuoyDetector.use('front_camera')))
define('buoy_detector', Cmp::BuoyDetector.use('front_camera'))

define('wall', Cmp::VisualServoing.use(Cmp::WallDetector.use('sonar')))
define('wall_detector', Cmp::WallDetector.use('sonar'))
 
