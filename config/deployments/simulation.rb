Roby.app.load_orocos_deployment 'main'

#add(Cmp::ControlLoop).
#    use(Cmp::AUVJoystickCommand.use(Controldev::Local))

#add(Cmp::AUVJoystickCommand).
#    use(Controldev::Local)

add_mission(Taskmon::Task)

use Srv::Pose => Cmp::Localization
use Srv::Speed => AvalonSimulation::StateEstimator
use Srv::Orientation => AvalonSimulation::StateEstimator
use Srv::OrientationWithZ => AvalonSimulation::StateEstimator

use device("sonar") => device("sonar").use_deployments(/sonar/)

class AvalonSimulation::StateEstimator
    on :start do |event|
        @reader = data_reader :pose_samples
    end
    poll do
        if samples = @reader.read
            State.pose = samples
        end
    end
end

# Configure tasks for use in simulation
use AvalonControl::MotionControlTask => AvalonControl::MotionControlTask.
  use_conf("default", "simulation")
use SonarFeatureEstimator::Task => SonarFeatureEstimator::Task.
  use_conf('default','simulation')
use Buoydetector::Task => Buoydetector::Task.
  use_conf("default", "simulation")

add_mission('bottom_camera')
add_mission('front_camera')
add_mission('left_unicap_camera')
add_mission(AvalonSimulation::Task)
add_mission(AvalonSimulation::StateEstimator)
add_mission(AvalonSimulation::Actuators)
add_mission("sonar")
add_mission("sonar_rear")
add_mission(Cmp::UwvModel)
