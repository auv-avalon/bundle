    

#Anything shared by the robot and the simulator
define('relative_position_control', Cmp::ControlLoop.
    use('command' => AuvRelPosController::Task).
    use('controller' => AvalonControl::MotionControlTask))

define('drive_simple', Cmp::ControlLoop.
    use('command' => Cmp::AUVJoystickCommand).
    use('controller' => AvalonControl::MotionControlTask))

servoing = {
    'buoy' => Cmp::BuoyDetector.use('front_camera'),

    'pipeline' => Cmp::PipelineDetector.use('bottom_camera'),

    'wall' => Cmp::WallDetector.
       use(device('sonar').use_conf('default', 'wall_servoing_front')),

    'asv' => Cmp::AsvDetector.use('left_unicap_camera'),

    'dual_wall' => Cmp::DualSonarWallDetector.
       use('sonar_front' => device('sonar').use_conf('default', 'dual_wall_servoing')).
       use('sonar_rear' => device('sonar_rear').use_conf('default_rear', 'sonar_rear_right'))
}

servoing.each do |name, cmp|
    define(name, Cmp::VisualServoing.use(cmp))
    define("#{name}_detector", cmp)
end

wall_device = device('sonar').use_conf('default', 'wall_servoing_front')
wall_front_left = Cmp::WallDetector.use(wall_device)
wall_front_left.use(WallServoing::SingleSonarServoing.use_conf('default', 'wall_front_left'))
define('wall_front_left', Cmp::VisualServoing.use(wall_front_left))

wall_front_right = Cmp::WallDetector.use(wall_device)
wall_front_right.use(WallServoing::SingleSonarServoing.use_conf('default', 'wall_front_right'))
define('wall_front_right', Cmp::VisualServoing.use(wall_front_right))

wall_left = Cmp::WallDetector.use(device('sonar').use_conf('default', 'wall_servoing_left'))
wall_left.use(WallServoing::SingleSonarServoing.use_conf('default', 'wall_left'))
define('wall_left', Cmp::VisualServoing.use(wall_left))

wall_right = Cmp::WallDetector.use(device('sonar').use_conf('default', 'wall_servoing_right'))
wall_right.use(WallServoing::SingleSonarServoing.use_conf('default', 'wall_right'))
define('wall_right', Cmp::VisualServoing.use(wall_right))

define('hough_localization', Cmp::SonarWallHough.use('sonar'))
define('particle_localization', Cmp::Localization.use('sonar'))
define('navigation', Cmp::Navigation.use(Cmp::Localization.use('sonar')))

model.data_service_type "NavigationMode"
Cmp::ControlLoop.provides Srv::NavigationMode
Cmp::VisualServoing.provides Srv::NavigationMode

modality_selection Srv::NavigationMode, 'drive_simple', 'relative_position_control', 
    'pipeline', 'buoy', 'asv'


