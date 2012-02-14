#Anything shared by the robot and the simulator

define('relative_position_control', Cmp::ControlLoop).
  use('command' => AuvRelPosController::Task)

define('drive_simple', Cmp::ControlLoop).
  use('command' => Cmp::AUVJoystickCommand)

define('pipeline', Cmp::VisualServoing.use(Cmp::PipelineDetector.use('bottom_camera')))
define('pipeline_detector', Cmp::PipelineDetector.use('bottom_camera'))

define('pipeline_sonar', Cmp::VisualServoing.use(Cmp::PipelineSonarDetector))
define('pipeline_sonar_detector', Cmp::PipelineSonarDetector)

define('buoy', Cmp::VisualServoing.use(Cmp::BuoyDetector.use('front_camera')))
define('buoy_detector', Cmp::BuoyDetector.use('front_camera'))

define('asv', Cmp::VisualServoing.use(Cmp::AsvDetector.use('left_unicap_camera')))
define('asv_detector', Cmp::AsvDetector.use('left_unicap_camera'))

define('rotation', Cmp::VisualServoing.use(Cmp::Rotation.use('bottom_camera')))

define('wall', Cmp::VisualServoing.use(Cmp::WallDetector.use('sonar')))
define('wall_detector', Cmp::WallDetector.use('sonar'))

sonar_device = device('sonar').use_conf('default', 'distance_estimation')
define('sonar_distance', Cmp::VisualServoing.use(Cmp::WallDetector.use(sonar_device)))
define('sonar_distance_detector', Cmp::WallDetector.use(sonar_device))

model.data_service_type "NavigationMode"
Cmp::ControlLoop.provides Srv::NavigationMode
Cmp::VisualServoing.provides Srv::NavigationMode

nav_modes = ['drive_simple', 'pipeline', 'buoy', 'asv', 'rotation', 'pipeline_sonar']

modality_selection Srv::NavigationMode, *nav_modes


# Show supervision all available selction modes with joysticks button mapping
Robot.info "Available selection modes:"
nav_modes.each_with_index do |v, i|
    Robot.info "- mode #{i}, #{v} (on Button #{i+3})"
end

# define_wall_servoing(define_name, :sonar => sonar_config, :detector => detector_config)
#
#   creates a define for the wall servoing, where
#
#     define_name is the definition name
#     the sonar is configured in [sonar, sonar_config] mode
#     the detector (sonardetector::task) is configured in [default, detector_config] mode


#MAGO 21092011 removed everythin in the method
def define_wall_servoing(name, cmp, options = Hash.new)
#    options = Kernel.validate_options options,
#        :sonar => nil, :detector => nil
#
#    sonar_config = ['sonar']
#    sonar_config << options[:sonar] if options[:sonar]
#
#    detector_config = ['default']
#    detector_config << options[:detector] if options[:detector]
#    
#    sonar = Roby.orocos_engine.device('sonar').
#        use_conf(*sonar_config)
#
#    #task = if cmp == Cmp::WallDetector then
#     #          Sonardetector::Task
#     #      else 
#      #         SonarServoing::Task
#      #     end
#    
#
#    task = Sonardetector::Task
#
#    detector = cmp.use(sonar, task.use_conf(*detector_config))
#    Roby.orocos_engine.define("#{name}_detector", detector)
#    Roby.orocos_engine.define("#{name}", Cmp::VisualServoing.use(detector))
end

# -----------------------------------------------------------------------------
# definitions using WALL DETECTOR
# -----------------------------------------------------------------------------

#define_wall_servoing 'wall_left', Cmp::WallDetector,
#    :sonar => 'narrow_front', :detector => 'drive_left'

#define_wall_servoing 'wall_approach', Cmp::WallDetector,
#    :sonar => 'wall_approach',     :detector => 'wall_approach'

#define_wall_servoing 'wall_approach_buoy', Cmp::WallDetector,
#    :sonar => 'scan_right',        :detector => 'approach_buoy'

#define_wall_servoing 'wall_servoing_right_wall', Cmp::WallDetector, 
#    :sonar => 'scan_right',        :detector => 'servo_right_wall'

#narrow_sonar = device('sonar').use_conf('sonar', 'narrow_front')
#define('wall_detector', Cmp::WallDetector.use(narrow_sonar))

#narrow_sonar = device('sonar').use_conf('sonar', 'wall_approach')
#define('wall_distance_estimator', Cmp::WallDetector.use(narrow_sonar))


