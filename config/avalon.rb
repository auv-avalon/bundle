#Roby.app.orocos_process_server 'front','192.168.128.50', :log_dir => '/mnt/logs/log', :result_dir => '/mnt/logs/results'
#Roby.app.use_deployments_from "avalon_front", :on => 'front'

Roby.app.use_deployments_from "avalon_front"
Roby.app.use_deployments_from "avalon_back"

State.orocos.exclude_from_log '/canbus/Message'

# Does not work in multihost
# Roby.app.orocos_start_all_deployments = true

Conf.orocos.log_group "images" do
    add "/RTT/extras/ReadOnlyPointer</base/samples/frame/Frame>"
end

Conf.orocos.log_group "raw_camera" do
    # add "front_camera.frame_raw"
    # add "front_camera.frame"
    # add "bottom_camera.frame"
    add "camera_unicap_left.frame"
    add "camera_unicap_right.frame"
end

# Conf.orocos.disable_log_group "images"
Conf.orocos.disable_log_group "raw_camera"

StateEstimator::Task.worstcase_processing_time 1

State.navigation_mode = ['drive_simple','pipeline','pipeline_sonar']

Robot.devices do
#  device(Dev::LowLevel, :as => 'low_level_board').
#    period(0.3)
  device(Dev::XsensImu, :as => 'imu').
    period(0.01)
  device(Dev::Dsp3000, :as => 'fog').
    period(0.01)
  device(Dev::Micron, :as => 'sonar').
    period(0.01).
    use_conf("studiobad")
  device(Dev::Profiling, :as => 'profiler').
    period(0.1)
  device(Dev::BlueView, :as => 'blueview').
    period(0.1)
  device(Dev::Dynamixel, :as => 'dynamixel').
    device_id("/dev/ttyS3")
  
  #device(Dev::Micron, :as => "sonar_profiling_micron").
  #  period(0.01).
  #  use_conf('sonar_profiling_micron')
  
  device(Dev::Micron, :as => "sonar_rear").
    period(0.01).
    use_conf('sonar_rear')

  device(Dev::CameraProsilica, :as => "front_camera").
    period(0.1).
    use_conf("default", "front_camera")

  device(Dev::CameraProsilica, :as => "bottom_camera").
    period(0.1).
    use_conf("default", "bottom_camera")

  device(Dev::CameraUnicap, :as => "left_unicap_camera").
      period(0.1).
      use_conf("default", "left_unicap_camera")

  device(Dev::CameraUnicap, :as => "right_unicap_camera").
      period(0.1).
      use_conf("default", "right_unicap_camera")

  com_bus(Dev::Canbus, :as => 'can0').
    device_id('can0')

  through 'can0' do
    hbridge = device(Dev::HbridgeSet).
        can_id(0,0x700).
	period(0.001).
	sample_size(4)

    hbridge.slave(Dev::Hbridges, :as => 'motors').
  	select_ids(6,3,-2,1,4,5)

    device(Dev::Modem, :as => 'modem').
    	can_id(0x1E0, 0x7FF).
	period(0.1)

    device(Dev::DepthReader, :ad => 'depth_reader').
    	can_id(0x111,0x7F0).
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
