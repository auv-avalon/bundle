#Roby.app.orocos_process_server 'front','192.168.128.50'
#Roby.app.use_deployments_from "avalon_front", :on => 'front'

Roby.app.use_deployments_from "avalon_back"

State.orocos.disable_logging

Robot.devices do
  device(LowLevel, :as => 'depth').
    period(0.3)
  device(XsensImu, :as => 'imu').
    period(0.01).
    device_id("/dev/xsens")
  device(Dsp3000, :as => 'fog').
    period(0.01)
  device(Micron, :as => 'sonar')
  device(Canbus, :as => 'canbus')
  device(HbridgeSet, :as => 'hbridge')
  	#slave(Hbridges).
	#select_ids(1,2,3,4,5)
end



