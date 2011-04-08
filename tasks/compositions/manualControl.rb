
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
using_task_library "modem_can"
using_task_library "raw_control_command_converter"
using_task_library "movement_experiment"
using_task_library "ekf_slam"
using_task_library "testbed_servoing"
using_task_library "image_preprocessing"
using_task_library "buoy_detector"
using_task_library "structured_light"
using_task_library "offshore_pipeline_detector"
using_task_library "frame_demultiplexer"
using_task_library "motion_estimation"

#composition "Cameras" do
#	add Srv::ImageProvider, :as => "bottom_camera"
#	add Srv::ImageProvider, :as => "front_camera"
#end

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

	export stateestimator.orientation_samples #do this before provides
	export imu.calibrated_sensors
	provides DataServices::Orientation
	provides DataServices::CalibratedIMUSensors 

	fog.orientation_samples.ignore
	stateestimator.position_samples.ignore
	connect fog.rotation => stateestimator.fog_samples#, :type => :buffer, :size => 1

	autoconnect
end



#AP Navigation: Experiment von Allan Conquest
composition 'MovementExperiment' do
	add MotionEstimation::Task
	#add DataServices::Pose
	#add DataServices::RawCommand 
	#add RawControlCommandConverter::Task, :as => "controlconverter"
	#add DataServices::Pose
	add MovementExperiment::Task, :as => "control"
	export control.motion_command
	provides Srv::AUVMotionCommand
	#autoconnect
end

composition 'RawCommandInputLocal' do
	add Controldev::Local 
	add RawControlCommandConverter::Movement, :as => "controlconverter"

	add DataServices::Orientation
	
	export controlconverter.motion_command
	provides Srv::AUVMotionCommand
	autoconnect
end


composition 'RawCommandInput' do
	add DataServices::RawCommand 
	add RawControlCommandConverter::Movement, :as => "controlconverter"

	#add DataServices::Orientation
	add Cmp::PoseEstimation
	
	export controlconverter.motion_command
	provides Srv::AUVMotionCommand
	autoconnect
end

#composition 'PositionCommandInput' do
#	add DataServices::RawCommand 
#	export controlconverter.motion_command
#	provides Srv::AUVMotionCommand
#	autoconnect
#end


composition "Slam" do
	add Cmp::PoseEstimation
	add EkfSlam::Task, :as => 'slam'
	add SonarDriver::Micron 
	export slam.pose_samples 	

	provides DataServices::Pose
	provides DataServices::Orientation	

	slam.acceleration_samples.ignore
	autoconnect
end

composition "SlamModemInput" do
	add ModemCan::Task, :as => "modem"
	add Cmp::Slam
	add AvalonControl::PositionControlTask, :as => "positionControl"
	#connect modem.position_commands positionControl.position_commands
	export positionControl.motion_commands
	provides Srv::AUVMotionCommand
	autoconnect
end

composition 'PoseEstimationEKF' do
	add Cmp::PoseEstimation
	add EkfSlam::Task, :as => 'slam'
	add SonarDriver::Micron 
	export slam.pose_samples
	provides DataServices::Pose
	autoconnect
end

composition 'SlamManualInput' do
	# Why cannot use Orientation as abstract and define pose estimation with use
	
	#add DataServices::Orientation
	add Cmp::PoseEstimation
	
	add DataServices::RawCommand 

	add EkfSlam::Task, :as => 'slam'
	add SonarDriver::Micron 
	add RawControlCommandConverter::Position, :as => "positionconverter"
	add AvalonControl::PositionControlTask, :as => "positionControl"
	export positionControl.motion_commands
	provides Srv::AUVMotionCommand
	#Not used by filter, should be removed soon
	#slam.orientation_samples_reference.ignore
	#slam.speed_samples.ignore
	slam.acceleration_samples.ignore
	#slam.acceleration_samples_imu.ignore

	autoconnect
end

composition 'BuoyDetector' do
	#add DataServices::RawCommand 
	add Srv::ImageProvider
	add ImagePreprocessing::Task, :as => 'imagePreprocessing'
	add BuoyDetector::Task, :as => 'buoyDetector'
	connect imagePreprocessing.out_frame_half_rgb =>  buoyDetector.frame
	imagePreprocessing.sync_in.ignore
	export buoyDetector.buoy 
	autoconnect
end

composition 'StructuredLight' do
    add Srv::ImageProvider
    add StructuredLight::Task, :as => 'structuredLight'
    add FrameDemultiplexer::Task, :as => 'frameDemultiplexer'
    structuredLight.frame.ignore
    export structuredLight.laser_scan
    export frameDemultiplexer.oframe
    provides DataServices::ImageProvider
    autoconnect
end

composition 'PipelineFollower' do
    add Srv::ImageProvider
    add OffshorePipelineDetector::Task, :as => 'offshorePipelineDetector'
   # export offshorePipelineDetector.pipeline
   # provides 
    autoconnect
end

composition 'Testbed' do
	# Why cannot use Orientation as abstract and define pose estimation with use
	
	#add DataServices::Orientation
	add Cmp::PoseEstimation

	add Cmp::BuoyDetector

	add TestbedServoing::Task, :as => 'testbedServoing'

	add EkfSlam::Task, :as => 'slam'
	add SonarDriver::Micron 
	#add RawControlCommandConverter::Position, :as => "positionconverter"
	add AvalonControl::PositionControlTask, :as => "positionControl"
	export positionControl.motion_commands
	provides Srv::AUVMotionCommand
	

	#Not used by filter, should be removed soon
	#slam.orientation_samples_reference.ignore
	#slam.speed_samples.ignore
	slam.acceleration_samples.ignore
	#slam.acceleration_samples_imu.ignore

	autoconnect
end

Cmp::ControlLoop.specialize 'controller' => AvalonControl::MotionControlTask do
	overload 'command', Srv::AUVMotionCommand
	
	
	#add DataServices::Orientation
	add Cmp::PoseEstimation
	#add XsensImu::Task, :as => 'imu'

	autoconnect
end

Cmp::ControlLoopGeneric.specialize 'controller' => AvalonControl::MotionControlTask do
	overload 'command', Srv::AUVMotionCommand
	
	
	add DataServices::Orientation
	#add Cmp::PoseEstimation
	#add XsensImu::Task, :as => 'imu'

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
