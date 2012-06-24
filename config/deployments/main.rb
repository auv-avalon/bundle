    

#Anything shared by the robot and the simulator
define('relative_position_control', Cmp::ControlLoop.
    use('command' => AuvRelPosController::Task).
    use('controller' => AvalonControl::MotionControlTask))

define('drive_simple', Cmp::ControlLoop.
    use('command' => Cmp::AUVJoystickCommand).
    use('controller' => AvalonControl::MotionControlTask))

define('uwv_dynamic_model', Cmp::UwvModel)
define('hough_localization', Cmp::SonarWallHough.use('sonar'))
define('particle_localization', Cmp::Localization.use('sonar').use(Cmp::OrientationEstimator))
define('localization', Cmp::DualLocalization.use('sonar').use(Cmp::OrientationEstimator))
define('navigation', Cmp::Navigation.use(Cmp::DualLocalization.use('sonar').use(Cmp::OrientationEstimator)))
define('pingersearch', Cmp::Pingersearch)

define('cross_sonar', Cmp::DualSonarWallDetector. 
       use('sonar_front' => device('sonar').use_conf('default', 'straight_front')).
       use('sonar_rear' => device('sonar_rear').use_conf('default_rear', 'straight_rear')))

servoing = {

    'asv' => Cmp::AsvDetector.
        use('camera_left' => device('left_unicap_camera')).
        use('camera_right' => device('left_unicap_camera')),

    'buoy' => Cmp::BuoyDetector.use('front_camera'),

    'pipeline' => Cmp::PipelineDetector.use('bottom_camera'),

    'wall' => Cmp::WallDetector.
       use(device('sonar').use_conf('default', 'wall_servoing_front')),

    'dual_wall' => Cmp::DualSonarWallDetector.
       use('sonar_front' => device('sonar').use_conf('default', 'dual_wall_servoing')).
       use('sonar_rear' => device('sonar_rear').use_conf('default_rear', 'sonar_rear_right')),

    'wall_front_left' => Cmp::WallDetector.
        use(device('sonar').use_conf('default', 'wall_servoing_front')).
        use(WallServoing::SingleSonarServoing.use_conf('default', 'wall_front_left')),

    'wall_front_right' => Cmp::WallDetector.
        use(device('sonar').use_conf('default', 'wall_servoing_front')).
        use(WallServoing::SingleSonarServoing.use_conf('default', 'wall_front_right')),

   'wall_left' => Cmp::WallDetector.
        use(device('sonar').use_conf('default', 'wall_serving_left')).
        use(WallServoing::SingleSonarServoing.use_conf('default', 'wall_left')),

   'wall_right' => Cmp::WallDetector.
        use(device('sonar').use_conf('default', 'wall_servoing_right')).
        use(WallServoing::SingleSonarServoing.use_conf('default', 'wall_right'))
}

servoing.each do |name, cmp|
    define(name, Cmp::VisualServoing.use(cmp))
    define("#{name}_detector", cmp)
end

model.data_service_type "NavigationMode"
Cmp::ControlLoop.provides Srv::NavigationMode
Cmp::VisualServoing.provides Srv::NavigationMode

modality_selection Srv::NavigationMode, 'drive_simple', 'relative_position_control', 
    'pipeline', 'buoy', 'asv'


