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


# define_wall_servoing(define_name, :sonar => sonar_config, :detector => detector_config)
#
#   creates a define for the wall servoing, where
#
#     define_name is the definition name
#     the sonar is configured in [sonar, sonar_config] mode
#     the detector (sonardetector::task) is configured in [default, detector_config] mode
def define_wall_servoing(name, cmp, options = Hash.new)
    options = Kernel.validate_options options,
        :sonar => nil, :detector => nil

    sonar_config = ['sonar']
    sonar_config << options[:sonar] if options[:sonar]

    detector_config = ['default']
    detector_config << options[:detector] if options[:detector]
    
    sonar = Roby.orocos_engine.device('sonar').
        use_conf(*sonar_config)

    #task = if cmp == Cmp::WallDetector then
     #          Sonardetector::Task
     #      else 
      #         SonarServoing::Task
      #     end
    task = Sonardetector::Task

    detector = cmp.use(sonar, task.use_conf(*detector_config))
    Roby.orocos_engine.define("#{name}_detector", detector)
    Roby.orocos_engine.define("#{name}", Cmp::VisualServoing.use(detector))
end

# -----------------------------------------------------------------------------
# definitions using SONAR DETECTOR
# -----------------------------------------------------------------------------

define_wall_servoing 'wall_left', Cmp::WallDetector,
    :sonar => 'narrow_front', :detector => 'drive_left'

define_wall_servoing 'wall_approach', Cmp::WallDetector,
    :sonar => 'wall_approach',     :detector => 'wall_approach'

define_wall_servoing 'wall_approach_buoy', Cmp::WallDetector,
    :sonar => 'scan_right',        :detector => 'approach_buoy'

define_wall_servoing 'wall_servoing_right_wall', Cmp::WallDetector, 
    :sonar => 'scan_right',        :detector => 'servo_right_wall'

narrow_sonar = device('sonar').use_conf('sonar', 'narrow_front')
define('wall_detector', Cmp::WallDetector.use(narrow_sonar))

narrow_sonar = device('sonar').use_conf('sonar', 'wall_approach')
define('wall_distance_estimator', Cmp::WallDetector.use(narrow_sonar))

# -----------------------------------------------------------------------------
# definitions using SONAR SERVOING (old one)
# -----------------------------------------------------------------------------

define_wall_servoing 'classic_wall', Cmp::ClassicWallDetector, 
    :sonar => 'narrow_front', :detector => 'default'


