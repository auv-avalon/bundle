Roby.app.load_orocos_deployment 'main'

use Srv::Orientation      => Cmp::OrientationEstimator
use Srv::OrientationWithZ => Cmp::OrientationEstimator
use Srv::Pose             => Cmp::PoseEstimator

use Cmp::OrientationEstimator => Cmp::OrientationEstimator.use('low_level_board')
use Cmp::PoseEstimator        => Cmp::PoseEstimator.use('sonar', Cmp::OrientationEstimator)

define('pose_estimator', Cmp::PoseEstimator)
define('orientation_estimator', Cmp::OrientationEstimator)

# Predeploy a few things to keep them always running
add_mission(Hbridge::Task)
add_mission(Cmp::OrientationEstimator)

# Add system monitoring
add_mission(Sysmon::Task)
# Add modem-can, to get a com channel to the base station
add_mission(ModemCan::Task)

add_mission(Taskmon::Task).on_server('localhost')
add_mission(Taskmon::Task).on_server('front')

