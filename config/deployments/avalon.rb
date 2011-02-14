#Roby.app.load_orocos_deployment 'avalon_back'
#Roby.app.use_deployments_from "avalon_back"

#add_mission(Canbus::Task)
#add_mission(Hbridge::Task)

define('drive_simple',Cmp::ControlLoopAvalon).
	use 'imu'

#Make definitions public because we are in an deployment, and the defiintions need on model
model.data_service_type "NavigationMode"
Compositions::ControlLoopAvalon.provides Srv::NavigationMode
modality_selection Srv::NavigationMode, "drive_simple"

add_mission(Sysmon::Task)






