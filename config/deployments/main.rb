#Anything shared by the robot and the simulator
define('relative_position_control', Cmp::ControlLoop.
    use('command' => AuvRelPosController::Task).
    use('controller' => AvalonControl::MotionControlTask))

define('drive_simple', Cmp::ControlLoop.
    use('command' => Cmp::AUVJoystickCommand).
    use('controller' => AvalonControl::MotionControlTask))


pipeline_detector = Cmp::PipelineDetector.use('bottom_camera')
define('pipeline', Cmp::VisualServoing.use(pipeline_detector))
define('pipeline_detector', pipeline_detector)

buoy_detector = Cmp::BuoyDetector.use('front_camera')
define('buoy', Cmp::VisualServoing.use(buoy_detector))
define('buoy_detector', buoy_detector)

## single sonar wall servoing
wall_device = device('sonar').with_conf('default', 'wall_servoing_front')
define('wall', Cmp::VisualServoing.use(Cmp::WallDetector.use(wall_device)))
define('wall_detector', Cmp::WallDetector.use(wall_device))
wall_front_left = Cmp::WallDetector.use(wall_device)
wall_front_left.use(WallServoing::SingleSonarServoing.with_conf('default', 'wall_front_left'))
define('wall_front_left', Cmp::VisualServoing.use(wall_front_left))
wall_front_right = Cmp::WallDetector.use(wall_device)
wall_front_right.use(WallServoing::SingleSonarServoing.with_conf('default', 'wall_front_right'))
define('wall_front_right', Cmp::VisualServoing.use(wall_front_right))

wall_left = Cmp::WallDetector.use(device('sonar').with_conf('default', 'wall_servoing_left'))
wall_left.use(WallServoing::SingleSonarServoing.with_conf('default', 'wall_left'))
define('wall_left', Cmp::VisualServoing.use(wall_left))

wall_right = Cmp::WallDetector.use(device('sonar').with_conf('default', 'wall_servoing_right'))
wall_right.use(WallServoing::SingleSonarServoing.with_conf('default', 'wall_right'))
define('wall_right', Cmp::VisualServoing.use(wall_right))

## dual sonar wall servoing
dual_sonar_wall_detector = Cmp::DualSonarWallDetector.
    use('sonar_front' => device('sonar').with_conf('default', 'dual_wall_servoing'),
        'sonar_rear' => device('sonar_rear').with_conf('default_rear', 'sonar_rear_right'))
define('dual_wall', Cmp::VisualServoing.use(dual_sonar_wall_detector))

define('dual_distance_detector', Cmp::DualSonarWallDetector.
       use('sonar_front' => device('sonar').with_conf('default', 'dual_distance_x'),
           'sonar_rear'  => device('sonar_rear').with_conf('default_rear', 'dual_distance_y')))

define('asv', Cmp::VisualServoing.use(Cmp::AsvDetector.use('left_unicap_camera')))
define('asv_detector', Cmp::AsvDetector.use('left_unicap_camera'))

#define('pipeline_sonar', Cmp::VisualServoing.use(Cmp::PipelineSonarDetector))
#define('pipeline_sonar_detector', Cmp::PipelineSonarDetector)

hough_sonar = device('sonar')
define('sonar_wall_hough', Cmp::SonarWallHough.use(hough_sonar))

define('localization', Cmp::Localization.use('sonar'))
define('navigation', Cmp::Navigation.use(Cmp::Localization.use('sonar')))

model.data_service_type "NavigationMode"
Cmp::ControlLoop.provides Srv::NavigationMode
Cmp::VisualServoing.provides Srv::NavigationMode

modality_selection Srv::NavigationMode, 'drive_simple', 'relative_position_control', 
    'pipeline', 'buoy', 'asv'

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
#        with_conf(*sonar_config)
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
#    detector = cmp.use(sonar, task.with_conf(*detector_config))
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

#narrow_sonar = device('sonar').with_conf('sonar', 'narrow_front')
#define('wall_detector', Cmp::WallDetector.use(narrow_sonar))

#narrow_sonar = device('sonar').with_conf('sonar', 'wall_approach')
#define('wall_distance_estimator', Cmp::WallDetector.use(narrow_sonar))


