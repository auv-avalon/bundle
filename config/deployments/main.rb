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

narrow_sonar = device('sonar').use_conf('sonar', 'narrow')
wall_servoing_right = Cmp::WallDetector.use('sonar').
	use(narrow_sonar,Sonardetector::Task.use_conf("default","drive-right"))
wall_servoing_left = Cmp::WallDetector.use('sonar').
	use(narrow_sonar,Sonardetector::Task.use_conf("default","drive-left"))
define('wall_right', Cmp::VisualServoing.use(wall_servoing_right))
define('wall_left', Cmp::VisualServoing.use(wall_servoing_left))
define('wall_detector', Cmp::WallDetector.use(narrow_sonar))

# define_wall_servoing(define_name, :sonar => sonar_config, :detector => detector_config)
#
#   creates a define for the wall servoing, where
#
#     define_name is the definition name
#     the sonar is configured in [sonar, sonar_config] mode
#     the detector (sonardetector::task) is configured in [default, detector_config] mode
def define_wall_servoing(name, options = Hash.new)
    options = Kernel.validate_options options,
        :sonar => nil, :detector => nil

    sonar_config = ['sonar']
    sonar_config << options[:sonar] if options[:sonar]

    detector_config = ['default']
    detector_config << options[:detector] if options[:detector]
    
    sonar = Roby.orocos_engine.device('sonar').
        use_conf(*sonar_config)
    Roby.orocos_engine.define(name, Cmp::WallDetector.
           use(sonar, Sonardetector::Task.use_conf(*detector_config)))
end

define_wall_servoing 'wall_distance_estimator', :sonar => 'very_narrow_front', :detector => 'distance_estimator'
define_wall_servoing 'wall_approach_buoy' ,     :sonar => 'scan_right',        :detector => 'approach_buoy'
define_wall_servoing 'wall_servoing_right_wall',:sonar => 'scan_right',        :detector => 'servo_right_wall'

