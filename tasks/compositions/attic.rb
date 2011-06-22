# composition 'ManualDriving' do
#     add DataServices::RawCommand 
#     add RawControlCommandConverter::Movement, :as => "controlconverter"
#     add Cmp::ControlLoop
# 
#     autoconnect
# end
# 
# composition "SlamModemInput" do
# 	add ModemCan::Task, :as => "modem"
# 	add Cmp::PoseEstimation
# 	add AvalonControl::PositionControlTask, :as => "positionControl"
# 	#connect modem.position_commands positionControl.position_commands
# 	export positionControl.motion_commands
# 	provides Srv::AUVMotionCommand
# 	autoconnect
# end
# 
# 
# 
# 
# composition 'SlamManualInput' do
# 	add DataServices::Pose
# #	add Cmp::OrientationEstimator
# 	
# 	add DataServices::RawCommand 
# 
# #	add EkfSlam::Task, :as => 'slam'
# #	add SonarDriver::Micron 
# 	add RawControlCommandConverter::Position, :as => "positionconverter"
# 	add AvalonControl::PositionControlTask, :as => "positionControl"
# 	export positionControl.motion_commands, :as => 'command'
# 	provides Srv::AUVMotionCommand
# 	#Not used by filter, should be removed soon
# 	#slam.orientation_samples_reference.ignore
# 	#slam.speed_samples.ignore
# 	#slam.acceleration_samples.ignore
# 	#slam.acceleration_samples_imu.ignore
# 
# 	autoconnect
# end
# 
# #composition 'BuoyDetector' do
# #	#add DataServices::RawCommand 
# #	add Srv::ImageProvider
# #	add ImagePreprocessing::Task, :as => 'imagePreprocessing'
# #	add BuoyDetector::Task, :as => 'buoyDetector'
# #	connect imagePreprocessing.out_frame_half_rgb =>  buoyDetector.frame
# #	imagePreprocessing.sync_in.ignore
# #	export buoyDetector.buoy 
# #	autoconnect
# #end
# 
# composition 'Testbed' do
# #	# Why cannot use Orientation as abstract and define pose estimation with use
# #	
# #	#add DataServices::Orientation
# #	add Cmp::PoseEstimation
# #
# #	add Cmp::BuoyDetector
# #
# #	add TestbedServoing::Task, :as => 'testbedServoing'
# #
# #	add EkfSlam::Task, :as => 'slam'
# #	add SonarDriver::Micron 
# #	#add RawControlCommandConverter::Position, :as => "positionconverter"
# #	add AvalonControl::PositionControlTask, :as => "positionControl"
# #	export positionControl.motion_commands
# #	provides Srv::AUVMotionCommand
# #	
# #
# #	#Not used by filter, should be removed soon
# #	#slam.orientation_samples_reference.ignore
# #	#slam.speed_samples.ignore
# #	slam.acceleration_samples.ignore
# #	#slam.acceleration_samples_imu.ignore
# #
# #	autoconnect
# end
# 
# 
