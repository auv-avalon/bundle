using_task_library "low_level_driver"
using_task_library "xsens_imu"
using_task_library "dsp3000"
using_task_library 'state_estimator'

using_task_library "sonar_driver"
#using_task_library "acoustic_modem"
using_task_library "avalon_control"
using_task_library "canbus"
using_task_library "hbridge"

composition "Minimal" do
	lowlevel = add LowLevelDriver::LowLevelTask, :as => 'lowlevel'
	xsens = add XsensImu::Task, :as => 'imu'
	fog = add Dsp3000::Task, :as => 'fog'
	stateestimator = add StateEstimator::Task, :as => 'stateestimator'
	add SonarDriver::SonarDriverMicronTask, :as => 'sonar'
	motion = add AvalonControl::MotionControlTask, :as => 'motioncontrol'
	can = add Canbus::Task, :as => 'can'
	hbridge = add Hbridge::Task, :as => 'hbridge'

        stateestimator.position_samples.ignore
        stateestimator.imu_sensor_samples.ignore
	connect xsens.orientation_samples => stateestimator.orientation_samples,  :type => :buffer, :size => 1
	connect lowlevel.depth_samples => stateestimator.depth_samples#,  :type => buffer, :size => 1
	connect fog.rotation => stateestimator.fog_samples, :type => :buffer, :size => 1
	connect stateestimator.pose_samples => motion.pose_samples, :type => :buffer, :size => 1
	

	autoconnect
end
