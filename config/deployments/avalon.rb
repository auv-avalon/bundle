Roby.app.load_orocos_deployment 'main'

use Cmp::OrientationWithZ => Cmp::OrientationWithZ.use('depth_reader').use(Cmp::DagonOrientationEstimator)

use Srv::Orientation      => Cmp::OrientationWithZ
use Srv::OrientationWithZ => Cmp::OrientationWithZ
use Srv::Speed            => Cmp::OrientationWithZ
use Srv::Pose             => Cmp::Localization.use('sonar')

#use Srv::GroundDistance   => device('sonar_rear') 
use Srv::GroundDistance   => device('echosounder') 
use Srv::SoundSourceDirection => Pingersearch::AngleEstimation

use DataServices::AUVMotionController => AvalonControl::MotionControlTask


define("base_control",Cmp::ControlLoop).use("hbridge_set")

use Cmp::ControlLoop.use(
	'controlled_system' => AvalonControl::MotionControlTask#,
#	'controller' => "base_control"
)




define('drive_simple', Cmp::ControlLoop).
#    #use(Cmp::AUVJoystickCommand.use(Srv::RawCommand => device('joystick')), 'controlled_system' => AvalonControl::MotionControlTask)
    use(Cmp::AUVJoystickCommand.use(Srv::RawCommand => device('joystick')))#, 'controlled_system' => AvalonControl::MotionControlTask)



#define('drive_simple', Cmp::BaseControl).
#	use(Cmp::AUVJoystickCommand.use(Srv::RawCommand => device('joystick')))

#use Cmp::OrientationEstimator => Cmp::OrientationEstimator.use('depth_reader') ##Depth Sensor as reference
#use Cmp::OrientationEstimator => Cmp::OrientationEstimator.use('sonar_rear') ##Ground distance as 0 reference !

use device("sonar") => device("sonar").use_deployments(/sonar/)

# !!! Configure tasks for specific location !!!
detector_conf = ["default"]
use OffshorePipelineDetector::Task => OffshorePipelineDetector::Task.
    with_conf(*detector_conf)
use OrientationEstimator::BaseEstimator => OrientationEstimator::BaseEstimator.
    with_conf('default','sauce12')

DepthReader::DepthAndOrientationFusion.on :start do |event|
   @pose_reader = data_reader 'pose_samples'
end
DepthReader::DepthAndOrientationFusion.poll do
   if !@pose_reader.nil?
       if rbs = @pose_reader.read
           State.pose.orientation = rbs.orientation
           if !State.pose.respond_to?(:position)
       	       State.pose.position = Eigen::Vector3.new(0, 0, 0)
           end
           State.pose.position.z = rbs.position.z
       end
   end
end

# Predeploy a few things to keep them always running
#add_mission(Hbridge::Task)

# Add system monitoring
add_mission(Sysmon::Task)
# Add modem-can, to get a com channel to the base station
#add_mission(ModemCan::Task)
#add_mission(BatteryManagement::Task)


# add_mission(Taskmon::Task).on_server('localhost')
# add_mission(Taskmon::Task).on_server('front')

#add_mission('particle_localization')
#add_mission(Cmp::ModemPositionOutput)
#add_mission('left_unicap_camera')
#add_mission('right_unicap_camera')

#Should be activated on real missions, maybe an MC-20 switch-state?, but modes to the"sensors" composition
#add_mission('bottom_camera')
#add_mission('front_camera')
#add_mission('gps')
#add_mission('sonar')
#add_mission('echosounder')

#comment this in to actiate sensors, or use the sensors define from shell
#add_mission(Cmp::Sensors.
#        use('front' => device("front_camera")).
#        use('bottom' => device("bottom_camera")))

#add_mission('sonar_rear')

add_mission(Cmp::OrientationWithZ)
#add_mission(Cmp::UwvModel)
#add_mission(Cmp::PipelineSonarDetector)

