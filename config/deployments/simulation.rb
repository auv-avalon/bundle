Roby.app.load_orocos_deployment 'main'
use_deployments_from 'controldev'
use_deployments_from 'avalon_back'

add(Cmp::ControlLoop).
    use(Cmp::AUVJoystickCommand.use(Controldev::Local))

#add(Cmp::AUVJoystickCommand).
#    use(Controldev::Local)

use DataServices::OrientationWithZ => AvalonSimulation::StateEstimator

use AvalonControl::MotionControlTask => AvalonControl::MotionControlTask.
  use_conf("default", "simulation")

add_mission(AvalonSimulation::Task)


### not finished or tested
