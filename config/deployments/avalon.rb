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
#add_mission(Cmp::MotionEstimation) #Movemnt model

#add_mission(Cmp::OrientationEstimator)

# Add system monitoring
add_mission(Sysmon::Task)
# Add modem-can, to get a com channel to the base station
add_mission(ModemCan::Task)

# add_mission(Taskmon::Task).on_server('localhost')
# add_mission(Taskmon::Task).on_server('front')

add_mission('bottom_camera')
#add_mission('blueview')

add_mission('front_camera')
#add_mission('left_unicap_camera')
#add_mission('right_unicap_camera')

#add_mission('profiler')
add_mission('sonar')
#add_mission('sonar_profiling_micron') # removed now 061011 (MG)
add_mission('sonar_rear')

add_mission("orientation_estimator")
add_mission(Cmp::DagonOrientationEstimator)
#add_mission(Cmp::UwvModel)
#add_mission(Cmp::PipelineSonarDetector)

