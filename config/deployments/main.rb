    
use Cmp::BuoyDetector => Cmp::BuoyDetector.use('front_camera')

#Anything shared by the robot and the simulator
define('relative_position_control', Cmp::ControlLoop.
    use('command' => AuvRelPosController::Task).
    use('controller' => AvalonControl::MotionControlTask))

define('drive_simple', Cmp::ControlLoop.
    use('command' => Cmp::AUVJoystickCommand).
    use('controller' => AvalonControl::MotionControlTask))

define('uwv_dynamic_model', Cmp::UwvModel)
define('hough_localization', Cmp::SonarWallHough.use('sonar'))
define('particle_localization', Cmp::Localization.use('sonar'))
define('localization', Cmp::DualLocalization.use('sonar'))
define('navigation', Cmp::Navigation.use(Cmp::Localization.use('sonar')))
define('asv_and_pinger', Cmp::AsvAndPingersearch)
define('modem_listener', Cmp::ModemListener)

define('cross_sonar', Cmp::DualSonarWallDetector. 
       use('sonar_front' => device('sonar').use_conf('default', 'straight_front')).
       use('sonar_rear' => device('sonar_rear').use_conf('default_rear', 'straight_rear')))

servoing = {

    'buoy' => Cmp::BuoyDetector,

    'pipeline' => Cmp::PipelineDetector.use('bottom_camera'),

    'pingersearch' => Cmp::Pingersearch,

    'wall' => Cmp::WallDetector.
       use(device('sonar').use_conf('default', 'wall_servoing_front')).
        use(SonarFeatureEstimator::Task.use_conf('default', 'wall_servoing')),

    'dual_wall' => Cmp::DualSonarWallDetector.
       use('sonar_front' => device('sonar').use_conf('default', 'dual_wall_servoing')).
       use('sonar_rear' => device('sonar_rear').use_conf('default_rear', 'sonar_rear_right')),

    'wall_front_align' => Cmp::WallDetector.
        use(device('sonar').use_conf('default', 'wall_servoing_front_far')).
        use(WallServoing::SingleSonarServoing.use_conf('default', 'wall_front')).
        use(SonarFeatureEstimator::Task.use_conf('default', 'wall_servoing')),

    'wall_front_left' => Cmp::WallDetector.
        use(device('sonar').use_conf('default', 'wall_servoing_front')).
        use(WallServoing::SingleSonarServoing.use_conf('default', 'wall_front_left')).
        use(SonarFeatureEstimator::Task.use_conf('default', 'wall_servoing')),

    'wall_front_right' => Cmp::WallDetector.
        use(device('sonar').use_conf('default', 'wall_servoing_front')).
        use(WallServoing::SingleSonarServoing.use_conf('default', 'wall_front_right')).
        use(SonarFeatureEstimator::Task.use_conf('default', 'wall_servoing')),

   'wall_left' => Cmp::WallDetector.
        use(device('sonar').use_conf('default', 'wall_servoing_left')).
        use(WallServoing::SingleSonarServoing.use_conf('default', 'wall_left')).
        use(SonarFeatureEstimator::Task.use_conf('default', 'wall_servoing')),

   'wall_right' => Cmp::WallDetector.
        use(device('sonar').use_conf('default', 'wall_servoing_right')).
        use(WallServoing::SingleSonarServoing.use_conf('default', 'wall_right')).
        use(SonarFeatureEstimator::Task.use_conf('default', 'wall_servoing'))
}

servoing.each do |name, cmp|
    define(name, Cmp::VisualServoing.use(cmp))
    define("#{name}_detector", cmp)
end
#Cmp::VisualServoing => Cmp::VisualServoing.use(Cmp::Pingersearch.use(AUVRelPosController::Task.use_conf('default','absolute_heading')))

model.data_service_type "NavigationMode"
Cmp::ControlLoop.provides Srv::NavigationMode
Cmp::VisualServoing.provides Srv::NavigationMode

modality_selection Srv::NavigationMode, 'drive_simple', 'relative_position_control', 
    'pipeline', 'buoy'


