LOCAL = false
if LOCAL
    Roby.app.use_deployments_from "avalon_front"
    Roby.app.use_deployments_from "avalon_back"
else
    Roby.app.orocos_process_server 'back', 'avalon-rear'
    Roby.app.use_deployments_from "avalon_front"
    Roby.app.use_deployments_from "avalon_back", :on => 'back'
end

State.config.demultiplexer_drop_rate = 1

Robot.devices do
    camera_config = Orocos::RobyPlugin::Camera::CameraTask::Config.new
    camera_config.binning_x      = 1
    camera_config.binning_y      = 1
    camera_config.region_x       = 9
    camera_config.region_y       = 7
    camera_config.width          = 640
    camera_config.height         = 480

    device(DfkiImu, :as => 'imu').
        device_id('/dev/dfki_imu').
        period(0.018).
	configure do |p|
	    p.max_timeouts = 100
	end

    device(XsensImu).
        period(0.010).
        device_id("/dev/xsens").
	configure do |p|
	    p.scenario = 'machine_nomagfield'
	    p.max_timeouts = 5
	end

    device(AvalonLowLevel, :as => 'lowlevel').
        device_id("/dev/lowlevel").
        period(0.008).
        configure do |p|
            p.longExposure  = 12000
            p.shortExposure = 5000
        end

    device(IfgFOG, :as => 'fog').
        period(0.01).
        device_id('/dev/ifg')

    device(Motcon, :as => 'motors').
        device_id("/dev/motcon")

    device(MicronSonar, :as => 'sonar').
        period(0.1).
        device_id('/dev/sonar')

    device(Dynamixel, :as => 'laser_servo').
        period(0.1).
        device_id('/dev/dynamixedynamixdynamixel

    #device(TritechModem, :as => 'modem').
    #    period(0.1).
    #    device_id('/dev/ttyS0')

    device(Camera, :as => 'front_camera').
        device_id('33186').
        period(0.03).
        configure(camera_config) do |p|
            p.trigger_mode   = 'sync_in1'
            p.exposure       = 5000
            p.exposure_mode  = 'external'
            p.fps            = 30
            p.gain           = 0
            p.gain_mode_auto = 0
            p.output_format  = 'rgb8'
            p.mode           = 'Master'
            p.log_interval_in_sec = 5
            p.synchronize_time_interval = 2000000
            p.frame_start_trigger_event = 'EdgeRising'
        end

    device(Camera, :as => 'bottom_camera').
        period(0.03).
        device_id('45050').
        configure(camera_config) do |p|
            p.trigger_mode = 'fixed'
            p.exposure = 15000
            p.exposure_mode = 'manual'
            p.fps = 20
            p.gain = 15
            p.gain_mode_auto = 0
            p.output_format = 'bayer8'
            p.log_interval_in_sec = 5
            p.mode = 'Master'
        end
end

