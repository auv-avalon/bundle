if !Roby.app.single?
    Roby.app.orocos_process_server 'front','192.168.128.50'
    Roby.app.use_deployments_from "avalon_front", :on => 'front'
else
    Roby.app.use_deployments_from "avalon_front"
end

Roby.app.use_deployments_from "avalon_back"

State.orocos.disable_logging


State.orocos.exclude_from_log '/canbus/Message'

#drive_simple = 0
#drive_slam = 1
#drive_testbed = 2
#drive_uwmodem = 3
#drive_allen = 4
#drive_dennis = 5
#drive_wall_servoing = 6
#pipeline = 7
State.navigation_mode = ['drive_simple',"drive_slam","pipeline","drive_testbed","drive_uwmodem","allan","dennis","wall_servoing"]#should load simpleControl

Robot.devices do
  device(Dev::LowLevel, :as => 'depth').
    period(0.3).
    device_id("/dev/ttyS0")
  device(Dev::XsensImu, :as => 'imu').
    period(0.01).
    device_id("/dev/ttyS2")
  device(Dev::Dsp3000, :as => 'fog').
    device_id("/dev/ttyS3").
    period(0.01)
  device(Dev::Micron, :as => 'sonar').
    device_id("/dev/ttyS0").
    configure do |task|
    	config = task.config
	config.numberOfBins  300
	config.adInterval  30
	config.initialGain  50
		
	#for front scanning
	config.pingpong=true
	config.cont = 0
	config.leftLimit = 2399
	config.rightLimit = 3999
	#front scanning end
	#
	task.config = config
    end
  device(Dev::Profiling, :as => 'profiler').
    device_id("/dev/ttyS1").
    configure do |task|
        c = task.config
	start = (6400.0/4.0)*1.0
	ende = start + (6400.0/4.0)
	c.config.leftLimit start
        c.config.rightLimit ende
        task.config = c
  end
  
  device(Dev::Dynamixel, :as => 'dynamixel').
    device_id("/dev/ttyS3")
  
  device(Dev::Micron, :as => "sonar_rear").
    device_id("/dev/ttyUSB0").
    configure do |task|
    	config = task.config
	config.leftLimit 1000 
	config.rightLimit 4000
	config.pingpong true
#	config.continues false
	config.numberOfBins  300
	config.adInterval  50
	config.initialGain  30
	task.config = config
   end

  device(Dev::Camera, :as => "front_camera").
    period(0.1).
    device_id("53093").
    configure do |task|
	task.camera_format = :MODE_BAYER
	task.log_interval_in_sec = 5
	task.mode = 'Master'
	task.binning_x = 1 
	task.binning_y = 1
	task.region_x = 712 
	task.region_y = 641
	task.width = 1024 
	task.height = 768
	task.trigger_mode = 'fixed'
	task.exposure_mode = 'manual'
	task.whitebalance_mode = 'manual'
	task.exposure = 5000
	task.fps = 10
	#task.gain = 0

	#task.trigger_mode = 'sync_in1'
	#task.exposure_mode = 'external'
	#task.frame_start_trigger_event = 'EdgeRising'
	task.scale_x = 0.5
	task.scale_y = 0.5
	task.resize_algorithm = :BAYER_RESIZE

	#task.synchronize_time_interval = 2000000
    end

  device(Dev::Camera, :as => "bottom_camera").
    period(0.1).
    device_id("33186").
    configure do |task|
	task.binning_x = 1
	task.binning_y = 1
	task.region_x = 9
	task.region_y = 7
	task.width =640
	task.height =480
	task.trigger_mode = 'fixed'
	task.exposure = 5000
	task.exposure_mode = 'auto'
	task.fps = 12
	task.gain = 15
	task.gain_mode_auto = 0
	task.camera_format = :MODE_BAYER
	task.log_interval_in_sec = 5
	task.mode = 'Master'
	task.scale_x = 0.5
	task.scale_y = 0.5
	task.resize_algorithm = :BAYER_RESIZE
    end

  com_bus(Dev::Canbus, :as => 'can0').
    device_id('can0').
    configure do |task|
    	task.deviceType = :SOCKET
    end

  through 'can0' do
    hbridge = device(Dev::HbridgeSet).
        can_id(0,0x700).
	period(0.001).
	sample_size(4)

    hbridge.slave(Dev::Hbridges, :as => 'motors').
  	select_ids(6,1,2,3,4,5)

    device(Dev::Modem, :as => 'modem').
    	can_id(0x1E0, 0x7FF).
	period(0.1)

    device(Dev::SystemStatus).
	can_id(0x101,0x7FF).
  	period(0.01)

    device(Dev::RemoteJoystick).
        period(0.01).
	can_id(0x100,0x7FF)

    device(Dev::ExperimentMarkers).
   	period(0.1).
	can_id(0x1C0,0x7FF)

    end
end

Roby::State.update do |s|
end
