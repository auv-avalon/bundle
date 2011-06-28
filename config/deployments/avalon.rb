Roby.app.load_orocos_deployment 'main'

#Roby.app.load_orocos_deployment 'avalon_back'
#Roby.app.use_deployments_from "avalon_back"

#add_mission(Canbus::Task)
#add_mission(Hbridge::Task)


#We use Matthias EKF For orientation estimation

use Srv::Orientation => Cmp::OrientationEstimator
use Srv::OrientationWithZ => Cmp::OrientationEstimator
use Srv::Pose        => Cmp::PoseEstimator

use Cmp::OrientationEstimator => Cmp::OrientationEstimator.use('low_level_board')
use Cmp::PoseEstimator => Cmp::PoseEstimator.use('sonar', Cmp::OrientationEstimator)

define('pose_estimator', Cmp::PoseEstimator)
define('orientation_estimator', Cmp::OrientationEstimator)

# define('drive_simple',Cmp::ControlLoop).
# 	use 'hbridge_set.motors',
# #	Cmp::OrientationEstimator, 
# #	AvalonControl::MotionControlTask, 
# 	Cmp::RawCommandInput
# 
# define('drive_slam',Cmp::ControlLoop).
# 	use Cmp::SlamManualInput.use('sonar'),
# 	DataServices::Orientation => Cmp::OrientationEstimator
# 
# define('drive_testbed',Cmp::ControlLoop).
# 	use 'hbridge_set.motors', AvalonControl::MotionControlTask, Cmp::Testbed, 'front_camera'
# 
# define('allan',Cmp::ControlLoop).
# 	use Cmp::OrientationEstimator,'hbridge_set.motors', AvalonControl::MotionControlTask, Cmp::MovementExperiment
# 
# define('drive_uwmodem',Cmp::ControlLoop).
# 	use 'hbridge_set.motors', AvalonControl::MotionControlTask, Cmp::SlamModemInput
# 
# define('dennis',Cmp::ControlLoop).
# 	use 'hbridge_set.motors', AvalonControl::MotionControlTask, Cmp::SlamModemInput
# 
# define('wall_servoing',Cmp::ControlLoop).
# 	use 'hbridge_set.motors', AvalonControl::MotionControlTask, Cmp::WallServoing.use('sonar')
# 
# define('pipeline',Cmp::ControlLoop).
# 	use 'hbridge_set.motors', AvalonControl::MotionControlTask, Cmp::PipelineFollower.use('bottom_camera')
# 
# #Make definitions public because we are in an deployment, and the defiintions need on model
# model.data_service_type "NavigationMode"
# Cmp::ControlLoop.provides Srv::NavigationMode
# modality_selection Srv::NavigationMode, "drive_simple","drive_slam","drive_testbed","drive_uwmodem","allan","dennis","wall_servoing","pipeline"
# 
# # # add_mission(Sysmon::Task)
# # # add_mission(Hbridge::Task)
# # # add_mission(Dynamixel::Task)
# # # add_mission(SonarDriver::Profiling)
# # # #add_mission(SonarDriver::Micron)
# # # add_mission(ModemCan::Task)
# # # add_mission("sonar_rear")
# # # add_mission("sonar")
# # # 
# # # add_mission(Cmp::OrientationEstimator). use "sonar"
# # # 
# # # add_mission('front_camera')
# # # add_mission('bottom_camera')
# # # add_mission(Cmp::PipelineDetector).use('bottom_camera')
# 
# #add_mission(Cmp::StructuredLight).
# #    use 'front_camera'
# 
# #add_mission(Cmp::PipelineFollower).
# #    use 'bottom_camera'
# 
# #add_mission(Cmp::BuoyDetector)
# #add_mission(Cmp::BuoyDetector).
# #	use Cmp::StructuredLight
# 
# #add_mission(Cmp::Testbed).
# #	use Cmp::StructuredLight
# 
# #add_mission(Compositions::Cameras).
# #	use "front_camera", "bottom_camera"
# 
# #add_mission(Camera::CameraTask).
# #	use "front_camera"
# 
# #add_mission("front_camera")
# #add_mission("bottom_camera")
# 
# 
# #add_mission(Camera::CameraTask).
# #	use 'bottom_camera'
# 
# 
