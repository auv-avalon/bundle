Roby.app.load_orocos_deployment 'main'

use Cmp::OrientationWithZ => Cmp::OrientationWithZ.use('depth_reader').use(Cmp::DagonOrientationEstimator)

use Srv::Orientation      => Cmp::OrientationWithZ
use Srv::OrientationWithZ => Cmp::OrientationWithZ
use Srv::Speed            => Cmp::OrientationWithZ
use Srv::Pose             => Cmp::Localization.use('sonar')

use Srv::GroundDistance   => device('sonar_rear') 
use Srv::SoundSourceDirection => Pingersearch::AngleEstimation

use DataServices::AUVMotionController => AvalonControl::MotionControlTask

#use Cmp::OrientationEstimator => Cmp::OrientationEstimator.use('depth_reader') ##Depth Sensor as reference
#use Cmp::OrientationEstimator => Cmp::OrientationEstimator.use('sonar_rear') ##Ground distance as 0 reference !

use device("sonar") => device("sonar").use_deployments(/sonar/)

use Cmp::AsvDetector => Cmp::AsvDetector.
    use('camera_right' => device('right_unicap_camera')).
    use('camera_left' => device('left_unicap_camera'))

# Connect right unicap camera only on AVALON, not in Simulation because there we have only one top cam
Cmp::AsvDetector.specialize 'camera_left' => CameraUnicap::CameraTask do
    #add Srv::ImageProvider, :as => 'camera_right'
    connect camera_right.images => detector.right_image
end

define('asv', Cmp::VisualServoing.use(Cmp::AsvDetector))
define('asv_detector', Cmp::AsvDetector)

# !!! Configure tasks for specific location !!!
detector_conf = ["default"]
use OffshorePipelineDetector::Task => OffshorePipelineDetector::Task.
    use_conf(*detector_conf)
use OrientationEstimator::BaseEstimator => OrientationEstimator::BaseEstimator.
    use_conf('default','sauce12')

DepthReader::DepthAndOrientationFusion.on :start do |event|
   @pose_reader = data_reader 'pose_samples'
end
DepthReader::DepthAndOrientationFusion.poll do
   if rbs = @pose_reader.read
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
#add_mission(BatteryManagement::Task)

# add_mission(Taskmon::Task).on_server('localhost')
# add_mission(Taskmon::Task).on_server('front')

add_mission('bottom_camera')
add_mission('front_camera')
add_mission('particle_localization')
add_mission(Cmp::ModemPositionOutput)
#add_mission('left_unicap_camera')
#add_mission('right_unicap_camera')

add_mission('gps')
add_mission('sonar')
add_mission('sonar_rear')

add_mission(Cmp::OrientationWithZ)
#add_mission(Cmp::UwvModel)
#add_mission(Cmp::PipelineSonarDetector)

