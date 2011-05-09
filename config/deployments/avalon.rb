#Roby.app.load_orocos_deployment 'avalon_back'
#Roby.app.use_deployments_from "avalon_back"

#add_mission(Canbus::Task)
#add_mission(Hbridge::Task)

define('drive_simple',Cmp::ControlLoop).
	use 'hbridge_set.motors',Cmp::PoseEstimation, AvalonControl::MotionControlTask, Cmp::RawCommandInput

define('drive_slam',Cmp::ControlLoop).
	use 'hbridge_set.motors', AvalonControl::MotionControlTask, Cmp::SlamManualInput.use('sonar_rear')

define('drive_testbed',Cmp::ControlLoop).
	use 'hbridge_set.motors', AvalonControl::MotionControlTask, Cmp::Testbed, 'front_camera'

define('allan',Cmp::ControlLoop).
	use Cmp::PoseEstimation,'hbridge_set.motors', AvalonControl::MotionControlTask, Cmp::MovementExperiment

define('drive_uwmodem',Cmp::ControlLoop).
	use 'hbridge_set.motors', AvalonControl::MotionControlTask, Cmp::SlamModemInput

define('dennis',Cmp::ControlLoop).
	use 'hbridge_set.motors', AvalonControl::MotionControlTask, Cmp::SlamModemInput

define('wall_servoing',Cmp::ControlLoop).
	use 'hbridge_set.motors', AvalonControl::MotionControlTask, Cmp::WallServoing.use('sonar')


#Make definitions public because we are in an deployment, and the defiintions need on model
model.data_service_type "NavigationMode"
Cmp::ControlLoop.provides Srv::NavigationMode
modality_selection Srv::NavigationMode, "drive_simple","drive_slam","drive_testbed","drive_uwmodem","allan","dennis","wall_servoing"

add_mission(Sysmon::Task)
add_mission(Hbridge::Task)
add_mission(Dynamixel::Task)
#add_mission(SonarDriver::Profiling)
#add_mission(SonarDriver::Micron)
add_mission(ModemCan::Task)
add_mission("sonar_rear")

#add_mission(Cmp::PoseEstimationEKF). use "sonar"

add_mission('front_camera')
add_mission('bottom_camera')
#add_mission(Cmp::StructuredLight).
#    use 'front_camera'

#add_mission(Cmp::PipelineFollower).
#    use 'bottom_camera'

#add_mission(Cmp::BuoyDetector)
#add_mission(Cmp::BuoyDetector).
#	use Cmp::StructuredLight

#add_mission(Cmp::Testbed).
#	use Cmp::StructuredLight

#add_mission(Compositions::Cameras).
#	use "front_camera", "bottom_camera"

#add_mission(Camera::CameraTask).
#	use "front_camera"

#add_mission("front_camera")
#add_mission("bottom_camera")


#add_mission(Camera::CameraTask).
#	use 'bottom_camera'


