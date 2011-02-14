#Roby.app.orocos_process_server 'front','192.168.128.50'
#Roby.app.use_deployments_from "avalon_front", :on => 'front'

Roby.app.use_deployments_from "avalon_back"

State.orocos.disable_logging

State.navigation_mode = 'drive_simple' #should load simpleControl

Robot.devices do
  device(Dev::LowLevel, :as => 'depth').
    period(0.3)
  device(Dev::XsensImu, :as => 'imu').
    period(0.01).
    device_id("/dev/xsens")
  device(Dev::Dsp3000, :as => 'fog').
    period(0.01)
  device(Dev::Micron, :as => 'sonar')

  com_bus(Dev::Canbus, :as => 'can0').
    device_id 'can0'


  through 'can0' do
    hbridge = device(Dev::HbridgeSet).
        can_id(0,0x7FF).
	period(0.001).
	sample_size(4)

    hbridge.slave(Dev::Hbridges).
  	select_ids(1,2,3,4,5,6)

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



