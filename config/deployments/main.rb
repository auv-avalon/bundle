#Anything shared by the robot and the simulator

define('testing', Cmp::ControlLoop).
  use(AuvRelPosController::Task)

define('drive_simple', Cmp::ControlLoop).
  use(Cmp::AUVJoystickCommand)

define('pipeline', Cmp::VisualServoing.use(Cmp::PipelineDetector.use('bottom_camera')))
define('pipeline_detector', Cmp::PipelineDetector.use('bottom_camera'))

define('buoy', Cmp::VisualServoing.use(Cmp::BuoyDetector.use('front_camera')))
define('buoy_detector', Cmp::BuoyDetector.use('front_camera'))

narrow_sonar = device('sonar').use_conf('sonar', 'narrow')
wall_servoing_right = Cmp::WallDetector.use('sonar').
	use(narrow_sonar,Sonardetector::Task.use_conf("default","drive-right"))
wall_servoing_left = Cmp::WallDetector.use('sonar').
	use(narrow_sonar,Sonardetector::Task.use_conf("default","drive-left"))
define('wall_right', Cmp::VisualServoing.use(wall_servoing_right))
define('wall_left', Cmp::VisualServoing.use(wall_servoing_left))
define('wall_detector', Cmp::WallDetector.use(narrow_sonar))
 
