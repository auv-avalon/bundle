
using_task_library "low_level_driver"
using_task_library "xsens_imu"
using_task_library "dsp3000"
using_task_library 'state_estimator'

using_task_library "sonar_driver"
#using_task_library "acoustic_modem"
using_task_library "avalon_control"
using_task_library "canbus"
using_task_library "hbridge"
using_task_library "sysmon"
using_task_library "controldev"
using_task_library "raw_control_command_converter"
using_task_library "movement_experiment"

composition "Cameras" do
	add Srv::ImageProvider, :as => "bottom_camera"
	add Srv::ImageProvider, :as => "front_camera"
end

#add_mission(Camera::CameraTask).
#	use "front_camera"

#add_mission("front_camera")
#add_mission("bottom_camera")
#add_mission(Camera::CameraTask).
#	use 'bottom_camera'



composition "PoseEstimation" do
	add LowLevelDriver::LowLevelTask, :as => 'lowlevel'
	add XsensImu::Task, :as => 'imu'

	add Dsp3000::Task, :as => 'fog'
	add StateEstimator::Task, :as => 'stateestimator'

	export stateestimator.pose_samples #do this before provides
	provides DataServices::Pose

	fog.orientation_samples.ignore
	stateestimator.position_samples.ignore
	connect fog.rotation => stateestimator.fog_samples#, :type => :buffer, :size => 1

	autoconnect
end

#AP Navigation: Experiment von Allan Conquest
composition 'MovementExperiment' do
	#add DataServices::RawCommand 
	#add RawControlCommandConverter::Task, :as => "controlconverter"
	#add DataServices::Pose
	add MovementExperiment::Task, :as => "control"
	export control.motion_command
	provides Srv::AUVMotionCommand
	#autoconnect
end

composition 'RawCommandInput' do
	add DataServices::RawCommand 
	add RawControlCommandConverter::Task, :as => "controlconverter"
	add DataServices::Pose

	export controlconverter.motion_command
	provides Srv::AUVMotionCommand
	autoconnect
end

Cmp::ControlLoop.specialize 'controller' => AvalonControl::MotionControlTask do
	overload 'command', Srv::AUVMotionCommand
	add DataServices::Pose

	autoconnect
end



#composition "Scanning-Sonar" do # not useful for only one task
#	sonar = add SonarDriver::SonarDriverMicronTask, :as => 'sonar'
#	export sonar.BaseScan
	# Do i need an provides
#end
#composition "Minimal" do
	#can = add Canbus::Task, :as => 'can'
	#stateestimator.depth_samples.ignore
#	autoconnect
#end
