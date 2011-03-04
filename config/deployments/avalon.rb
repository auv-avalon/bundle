#Roby.app.load_orocos_deployment 'avalon_back'
#Roby.app.use_deployments_from "avalon_back"

#add_mission(Canbus::Task)
#add_mission(Hbridge::Task)

define('drive_simple',Cmp::ControlLoop).
	use 'hbridge_set.motors', AvalonControl::MotionControlTask, Cmp::RawCommandInput

define('drive_slam',Cmp::ControlLoop).
	use 'hbridge_set.motors', AvalonControl::MotionControlTask, Cmp::SlamManualInput

define('drive_experiment',Cmp::ControlLoop).
	use Cmp::PoseEstimation,'hbridge_set.motors', AvalonControl::MotionControlTask, Cmp::MovementExperiment

#Make definitions public because we are in an deployment, and the defiintions need on model
model.data_service_type "NavigationMode"
Cmp::ControlLoop.provides Srv::NavigationMode
modality_selection Srv::NavigationMode, "drive_simple","drive_slam","drive_experiment"

add_mission(Sysmon::Task)
add_mission(Hbridge::Task)
add_mission(Dynamixel::Task)
add_mission(SonarDriver::Micron)
add_mission(ModemCan::Task)

#add_mission(Compositions::Cameras).
#	use "front_camera", "bottom_camera"

#add_mission(Camera::CameraTask).
#	use "front_camera"

add_mission("front_camera")
add_mission("bottom_camera")
#add_mission(Camera::CameraTask).
#	use 'bottom_camera'


