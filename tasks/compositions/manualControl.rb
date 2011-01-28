
using_task_library "low_level_driver"
using_task_library "xsens_imu"
using_task_library "dsp3000"
using_task_library 'state_estimator'

using_task_library "sonar_driver"
#using_task_library "acoustic_modem"
using_task_library "avalon_control"
using_task_library "canbus"
using_task_library "hbridge"


composition "PoseEstimation" do
	
	lowlevel = add LowLevelDriver::LowLevelTask, :as => 'lowlevel'
	#xsens = add XsensImu::Task, :as => 'imu'
	add Orientation#, :as => 'imu'
	fog = add Dsp3000::Task, :as => 'fog'
	stateestimator = add StateEstimator::Task, :as => 'stateestimator'

	export stateestimator.pose_samples #do this before provides
	provides DataServices::Pose

	fog.orientation_samples.ignore
	stateestimator.position_samples.ignore
        stateestimator.imu_sensor_samples.ignore
	#connect xsens.orientation_samples => stateestimator.orientation_samples#,  :type => :buffer, :size => 1
	connect lowlevel.depth_samples => stateestimator.depth_samples#,  :type => buffer, :size => 1
	connect fog.rotation => stateestimator.fog_samples#, :type => :buffer, :size => 1
	#connect stateestimator.pose_samples => motion.pose_samples#, :type => :buffer, :size => 1

	autoconnect
end

composition "ControlLoopAvalon" do
	add DataServices::Pose
	motion = add AvalonControl::MotionControlTask, :as => 'motioncontrol'
	hbridge = add Hbridge::Task, :as => 'hbridge'
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
