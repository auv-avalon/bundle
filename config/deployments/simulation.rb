#Roby.app.load_orocos_deployment 'avalon_back'
#Roby.app.use_deployments_from "avalon_back"

#add_mission(Canbus::Task)
#add_mission(Hbridge::Task)

define('drive_simple',Cmp::ControlLoopGeneric).
	use AvalonSimulation::Task, AvalonControl::MotionControlTask, Cmp::RawCommandInputLocal

define('drive_slam',Cmp::ControlLoop).
	use AvalonSimulation::Task, AvalonControl::MotionControlTask, Cmp::SlamManualInput

define('drive_testbed',Cmp::ControlLoop).
	use AvalonSimulation::Task, AvalonControl::MotionControlTask, Cmp::Testbed

define('drive_experiment',Cmp::ControlLoopGeneric).
	use AvalonSimulation::Task, AvalonControl::MotionControlTask, Cmp::MovementExperiment

#Make definitions public because we are in an deployment, and the defiintions need on model
model.data_service_type "NavigationMode"
Cmp::ControlLoopGeneric.provides Srv::NavigationMode
Cmp::ControlLoop.provides Srv::NavigationMode
modality_selection Srv::NavigationMode, "drive_simple","drive_slam","drive_testbed","drive_experiment"

#add_mission(Sysmon::Task)
#add_mission(Hbridge::Task)
#add_mission(Dynamixel::Task)
#add_mission(SonarDriver::Micron)
#add_mission(ModemCan::Task)

#add_mission(Cmp::BuoyDetector).
#	use "front_camera"

#add_mission(Camera::CameraTask).
#	use "front_camera"

#add_mission("bottom_camera")
#add_mission(Camera::CameraTask).
#	use 'bottom_camera'


