    
#use Cmp::BuoyDetector => Cmp::BuoyDetector.use('front_camera')


define 'motion_controller', Cmp::ControlLoop.use('controlled_system' => AvalonControl::MotionControlTask)

#define('drive_simple', Cmp::ControlLoop).
define('drive_simple', "motion_controller").
    use(Cmp::AUVJoystickCommand.use(Srv::RawCommand => device('joystick')))
    #use(Cmp::AUVJoystickCommand.use(Srv::RawCommand => device('joystick')), 'controlled_system' => AvalonControl::MotionControlTask)

#define('drive_simple', Cmp::ControlLoop).
#    use(Cmp::AUVJoystickCommand.use(Srv::RawCommand => device('joystick')))



##define("base_control", Cmp::ControlLoop).
##	use('hbridge_set', AvalonControl::MotionControlTask)

#use Srv::AUVMotionControlledSystem => "base_control"
#use Srv::RawCommand => device('joystick')


#Anything shared by the robot and the simulator
##define('relative_position_control', Cmp::ControlLoop.
##    use('command' => AuvRelPosController::Task).
##    use('controller' => AvalonControl::MotionControlTask))


#define('drive_simple', Cmp::ControlLoop).
#    use(Cmp::AUVJoystickCommand.use(Srv::RawCommand => device('joystick')))#, Srv::AUVMotionControlledSystem => AvalonControl::MotionControlTask)

#define('uwv_dynamic_model', Cmp::UwvModel)

##define('sensors', Cmp::Sensors.
##        use('front' => device("front_camera")).
##        use('bottom' => device("bottom_camera")))
##
##
##define('hough_localization', Cmp::SonarWallHough.use('sonar'))
##define('particle_localization', Cmp::Localization.use('sonar'))
##define('localization', Cmp::DualLocalization.use('sonar'))
##define('navigation', Cmp::Navigation.use(Cmp::Localization.use('sonar')))
##define('modem_listener', Cmp::ModemListener)

#define('cross_sonar', Cmp::DualSonarWallDetector. 
#       use('sonar_front' => device('sonar').with_conf('default', 'straight_front')).
#       use('sonar_rear' => device('sonar_rear').with_conf('default_rear', 'straight_rear')))



servoing = {

    'buoy' => Cmp::BuoyDetector,

    'pipeline' => Cmp::PipelineDetector.use('bottom_camera'),

    'pingersearch' => Cmp::Pingersearch,

    #'asv' => Cmp::SonarAsvDetector.use(device('sonar').with_conf('default','asv_search')),
    #'asv' => Cmp::SonarAsvDetector.use('sonar').with_conf('default','asv_search'),

    'wall' => Cmp::WallDetector.
       use(device('sonar').with_conf('default', 'wall_servoing_front')).
        use(SonarFeatureEstimator::Task.with_conf('default', 'wall_servoing')),

#    'dual_wall' => Cmp::DualSonarWallDetector.
#       use('sonar_front' => device('sonar').with_conf('default', 'dual_wall_servoing')).
#       use('sonar_rear' => device('sonar_rear').with_conf('default_rear', 'sonar_rear_right')),

    'wall_front_align' => Cmp::WallDetector.
        use(device('sonar').with_conf('default', 'wall_servoing_front_far')).
        use(WallServoing::SingleSonarServoing.with_conf('default', 'wall_front')).
        use(SonarFeatureEstimator::Task.with_conf('default', 'wall_servoing')),

    'wall_front_left' => Cmp::WallDetector.
        use(device('sonar').with_conf('default', 'wall_servoing_front')).
        use(WallServoing::SingleSonarServoing.with_conf('default', 'wall_front_left')).
        use(SonarFeatureEstimator::Task.with_conf('default', 'wall_servoing')),

    'wall_front_right' => Cmp::WallDetector.
        use(device('sonar').with_conf('default', 'wall_servoing_front')).
        use(WallServoing::SingleSonarServoing.with_conf('default', 'wall_front_right')).
        use(SonarFeatureEstimator::Task.with_conf('default', 'wall_servoing')),

   'wall_left' => Cmp::WallDetector.
        use(device('sonar').with_conf('default', 'wall_servoing_left')).
        use(WallServoing::SingleSonarServoing.with_conf('default', 'wall_left')).
        use(SonarFeatureEstimator::Task.with_conf('default', 'wall_servoing')),

   'wall_right' => Cmp::WallDetector.
        use(device('sonar').with_conf('default', 'wall_servoing_right')).
        use(WallServoing::SingleSonarServoing.with_conf('default', 'wall_right')).
        use(SonarFeatureEstimator::Task.with_conf('default', 'wall_servoing'))
}

#servoing.each do |name, cmp|
#    define(name, Cmp::VisualServoing.use(cmp))
#    define("#{name}_detector", cmp)
#end
servoing.each do |name, cmp|
    define(name, Cmp::ControlLoop).use(cmp, 'controlled_system' => AuvRelPosController::Task)
    define("#{name}_detector", cmp)
end

#Cmp::VisualServoing => Cmp::VisualServoing.use(Cmp::Pingersearch.use(AUVRelPosController::Task.with_conf('default','absolute_heading')))

#model.data_service_type "NavigationMode"
#Cmp::ControlLoop.provides Srv::NavigationMode
#Cmp::VisualServoing.provides Srv::NavigationMode

# 31.10.2012 Modularity Selection is broken an will be removd from Roby in general in future, so it should not hurt os to disable this "feature"
# modality_selection Srv::NavigationMode, 'drive_simple', 'relative_position_control', 
#     'pipeline', 'buoy'


