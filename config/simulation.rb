Roby.app.use_deployments_from "avalon_simulation"
Roby.app.use_deployments_from "avalon_back"

State.orocos.disable_logging


State.orocos.exclude_from_log '/canbus/Message'


State.navigation_mode = ['drive_simple',"drive_slam","drive_testbed"]#should load simpleControl

Robot.devices do
   device(Dev::Joystick)
   device(Dev::Simulator, :as => "Simulator").
   	slave(Dev::SimulatorControl)
#
#
#  device(Dev::LowLevel, :as => 'depth').
#    period(0.3)
#  device(Dev::XsensImu, :as => 'imu').
#    period(0.01).
#    device_id("/dev/xsens")
#  device(Dev::Dsp3000, :as => 'fog').
#    period(0.01)
#  device(Dev::Micron, :as => 'sonar').
#    configure do |task|
#    	config = task.config
#	config.numberOfBins 300
#	config.adInterval 30
#	config.initialGain 50
#	task.config = config
#    end
#  
#  device(Dev::Dynamixel, :as => 'dynamixel').
#    device_id("/dev/ttyUSB0")
#
#  device(Dev::Camera, :as => "front_camera").
#    period(0.1).
#    device_id("53093").
#    configure do |task|
#	task.binning_x = 1 
#	task.binning_y = 1
#	task.region_x = 712 
#	task.region_y = 641
#	task.width = 1024 
#	task.height = 768
#	task.trigger_mode = 'freerun'
#	task.exposure_mode = 'auto'
#	#task.trigger_mode = 'sync_in1'
#	#task.exposure_mode = 'external'
#	#task.whitebalance_mode = 'manual'
#	#task.exposure = 15000
#	task.fps = 10
#	#task.gain = 0
#	#task.gain_mode_auto = 0
#	task.output_format = 'bayer8'
#	#task.log_interval_in_sec = 5
#	#task.mode = 'Master'
#	#task.synchronize_time_interval = 2000000
##	task.frame_start_trigger_event = 'EdgeRising'
##	task.frame_start_trigger_event = 'FixedRate'
#    end
#
#  device(Dev::Camera, :as => "bottom_camera").
#    period(0.3).
#    device_id("33186").
#    configure do |task|
#	task.binning_x = 1
#	task.binning_y = 1
#	task.region_x = 9
#	task.region_y = 7
#	task.width =640
#	task.height =480
#	task.trigger_mode = 'fixed'
#	task.exposure = 5000
#	task.exposure_mode = 'manual'
#	task.fps = 20
#	task.gain = 15
#	task.gain_mode_auto = 0
#	#task.output_format = colorspace
#	task.log_interval_in_sec = 5
#	task.mode = 'Master'
#    end
#  
#
#  com_bus(Dev::Canbus, :as => 'can0').
#    device_id('can0').
#    configure do |task|
#    	task.deviceType = :SOCKET
#    end
#
#  through 'can0' do
#    hbridge = device(Dev::HbridgeSet).
#        can_id(0,0x700).
#	period(0.001).
#	sample_size(4)
#
#    hbridge.slave(Dev::Hbridges, :as => 'motors').
#  	select_ids(0,1,2,3,4,5)
#
#    device(Dev::Modem, :as => 'modem').
#    	can_id(0x1E0, 0x7FF).
#	period(0.1)
#
#    device(Dev::SystemStatus).
#	can_id(0x101,0x7FF).
#  	period(0.01)
#
#    device(Dev::RemoteJoystick).
#        period(0.01).
#	can_id(0x100,0x7FF)
#
#    device(Dev::ExperimentMarkers).
#   	period(0.1).
#	can_id(0x1C0,0x7FF)
#
#    end
end


Roby::State.update do |s|
end
