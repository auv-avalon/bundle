Roby.app.load_orocos_deployment 'main'

# !!! Configure tasks for specific location !!!
use Buoydetector::Task => Buoydetector::Task.
  use_conf("default", "testbed")

use Srv::Orientation      => Cmp::OrientationEstimator
use Srv::OrientationWithZ => Cmp::OrientationEstimator
use Srv::Pose             => Cmp::PoseEstimator

use DataServices::AUVMotionController => AvalonControl::MotionControlTask

use Cmp::OrientationEstimator => Cmp::OrientationEstimator.use('depth_reader') ##Depth Sensor as reference
#use Cmp::OrientationEstimator => Cmp::OrientationEstimator.use('sonar_rear') ##Ground distance as 0 reference !

# Connect right unicap camera only on AVALON, not in Simulation because there we have only one top cam
Cmp::AsvDetector.specialize 'camera_left' => CameraUnicap::CameraTask do
    connect camera_right.images => detector.right_image
end

wide_sonar = device('sonar').use_conf('sonar')
use Cmp::PoseEstimator        => Cmp::PoseEstimator.use(wide_sonar, Cmp::OrientationEstimator)

define('pose_estimator', Cmp::PoseEstimator)
define('orientation_estimator', Cmp::OrientationEstimator)

detector_conf = ["default", "studiobad"]

use Buoydetector::Task => Buoydetector::Task.
    use_conf(*detector_conf)
use OffshorePipelineDetector::Task => OffshorePipelineDetector::Task.
    use_conf(*detector_conf)

StateEstimator::Task.on :start do |event|
   @orientation_reader = data_reader 'orientation_samples'
end
StateEstimator::Task.poll do
   if rbs = @orientation_reader.read
       State.pose.orientation = rbs.orientation
       if !State.pose.respond_to?(:position)
       	   State.pose.position = Eigen::Vector3.new(0, 0, 0)
       end
       State.pose.position.z = rbs.position.z
   end
end

# Predeploy a few things to keep them always running
add_mission(Hbridge::Task)

# Add system monitoring
add_mission(Sysmon::Task)
# Add modem-can, to get a com channel to the base station
add_mission(ModemCan::Task)
add_mission(BatteryManagement::Task)

# add_mission(Taskmon::Task).on_server('localhost')
# add_mission(Taskmon::Task).on_server('front')

add_mission('bottom_camera')

add_mission('front_camera')
#add_mission('left_unicap_camera')
#add_mission('right_unicap_camera')

add_mission('gps')
add_mission('sonar')
add_mission('sonar_rear')

add_mission("orientation_estimator")
add_mission(Cmp::DagonOrientationEstimator)
#add_mission(Cmp::UwvModel)
#add_mission(Cmp::PipelineSonarDetector)

