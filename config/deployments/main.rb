#Anything shared by the robot and the simulator

define('testing', Cmp::ControlLoop).
  use(AuvRelPosController::Task)

define('drive_simple', Cmp::ControlLoop).
  use(Cmp::AUVJoystickCommand)

define('pipeline', Cmp::VisualServoing.use(Cmp::PipelineDetector.use('bottom_camera')))
define('pipeline_detector', Cmp::PipelineDetector.use('bottom_camera'))

define('buoy', Cmp::VisualServoing.use(Cmp::BuoyDetector.use('front_camera')))
define('buoy_detector', Cmp::BuoyDetector.use('front_camera'))

define('asv', Cmp::VisualServoing.use(Cmp::AsvDetector.use('left_unicap_camera')))
define('asv_detector', Cmp::AsvDetector.use('left_unicap_camera'))

define('rotation', Cmp::VisualServoing.use(Cmp::Rotation.use('bottom_camera')))

narrow_sonar = device('sonar').use_conf('sonar', 'narrow_front')
wall_servoing_right = Cmp::WallDetector.use('sonar').
	use(narrow_sonar,Sonardetector::Task.use_conf("default","drive-right"))
wall_servoing_left = Cmp::WallDetector.use('sonar').
	use(narrow_sonar,Sonardetector::Task.use_conf("default","drive-left"))
define('wall_right', Cmp::VisualServoing.use(wall_servoing_right))
define('wall_left', Cmp::VisualServoing.use(wall_servoing_left))
define('wall_detector', Cmp::WallDetector.use(narrow_sonar))


narrow_right_sonar = device('sonar').use_conf('sonar', 'narrow_right')
wall_servoing_follow_right = Cmp::WallDetector.
	use(narrow_right_sonar, Sonardetector::Task.use_conf("default","follow-right-wall"))
define('wall_follow_right', Cmp::VisualServoing.use(wall_servoing_follow_right))
define('wall_detector_right', Cmp::WallDetector.use(narrow_right_sonar))

