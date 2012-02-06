Roby.app.load_orocos_deployment 'main'

wall_sonar = device('sonar').use_conf('default','wall_servoing')
define('wall', Cmp::VisualServoing.use(
                    Cmp::WallDetector.use(wall_sonar).use(SonarFeatureEstimator::Task.use_conf('default', 'simulation'))))
#define('wall_detector', Cmp::WallDetector.use('sonar'))

#add(Cmp::ControlLoop).
#    use(Cmp::AUVJoystickCommand.use(Controldev::Local))

#add(Cmp::AUVJoystickCommand).
#    use(Controldev::Local)

add_mission(Taskmon::Task)

use DataServices::Orientation => AvalonSimulation::StateEstimator
use DataServices::OrientationWithZ => AvalonSimulation::StateEstimator

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

use AvalonControl::MotionControlTask => AvalonControl::MotionControlTask.
  use_conf("default", "simulation")

add_mission(AvalonSimulation::Task)
add_mission(AvalonSimulation::StateEstimator)
add_mission(AvalonSimulation::Actuators)
#add_mission(AvalonSimulation::SonarTop)
add_mission(Cmp::UwvModel)
#add_mission(AvalonSimulation::SonarBottom)

#test
add_mission("sonar")
# add_mission("sonar_rear")
