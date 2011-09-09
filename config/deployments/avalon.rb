Roby.app.load_orocos_deployment 'main'

use Srv::Orientation      => Cmp::OrientationEstimator
use Srv::OrientationWithZ => Cmp::OrientationEstimator
use Srv::Pose             => Cmp::PoseEstimator

use Cmp::OrientationEstimator => Cmp::OrientationEstimator.use('depth_reader')

wide_sonar = device('sonar').use_conf('sonar')
use Cmp::PoseEstimator        => Cmp::PoseEstimator.use(wide_sonar, Cmp::OrientationEstimator)

define('pose_estimator', Cmp::PoseEstimator)
define('orientation_estimator', Cmp::OrientationEstimator)

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
#add_mission(Cmp::OrientationEstimator)

# Add system monitoring
add_mission(Sysmon::Task)
# Add modem-can, to get a com channel to the base station
add_mission(ModemCan::Task)

# add_mission(Taskmon::Task).on_server('localhost')
# add_mission(Taskmon::Task).on_server('front')

add_mission('bottom_camera')
add_mission('blueview')
#add_mission('front_camera')
#add_mission('left_unicap_camera')
#add_mission('right_unicap_camera')

#add_mission('profiler')
#add_mission('sonar')
add_mission('sonar_rear')

add_mission("orientation_estimator")

