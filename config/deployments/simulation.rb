Roby.app.load_orocos_deployment 'main'

#add(Cmp::ControlLoop).
#    use(Cmp::AUVJoystickCommand.use(Controldev::Local))

#add(Cmp::AUVJoystickCommand).
#    use(Controldev::Local)

add_mission(Taskmon::Task)

use DataServices::Orientation => AvalonSimulation::StateEstimator
use DataServices::OrientationWithZ => AvalonSimulation::StateEstimator

use AvalonControl::MotionControlTask => AvalonControl::MotionControlTask.
  use_conf("default", "simulation")

add_mission(AvalonSimulation::Task)


### not finished or tested
