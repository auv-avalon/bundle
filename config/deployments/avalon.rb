Roby.app.load_orocos_deployment 'main'

use Srv::Orientation      => Cmp::OrientationEstimator
use Srv::OrientationWithZ => Cmp::OrientationEstimator
use Srv::Pose             => Cmp::PoseEstimator

use Cmp::OrientationEstimator => Cmp::OrientationEstimator.use('low_level_board')

wide_sonar = device('sonar').use_conf('sonar')
use Cmp::PoseEstimator        => Cmp::PoseEstimator.use(wide_sonar, Cmp::OrientationEstimator)

define('pose_estimator', Cmp::PoseEstimator)
define('orientation_estimator', Cmp::OrientationEstimator)

StateEstimator.on :start do |event|
   @orientation_reader = data_reader 'orientation_samples'
end
StateEstimator::Task.poll do
   if orientation = @orientation_reader.read
       State.pose.orientation = orientation
   end
end

# Predeploy a few things to keep them always running
add_mission(Hbridge::Task)
#add_mission(Cmp::OrientationEstimator)

# Add system monitoring
add_mission(Sysmon::Task)
# Add modem-can, to get a com channel to the base station
add_mission(ModemCan::Task)

add_mission(Taskmon::Task).on_server('localhost')
add_mission(Taskmon::Task).on_server('front')

add_mission('bottom_camera')
add_mission('front_camera')
add_mission('left_unicap_camera')
add_mission('right_unicap_camera')

add_mission("orientation_estimator")
