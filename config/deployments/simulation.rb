Roby.app.load_orocos_deployment 'main'

# use_deployments_from 'controldev'
use DataServices::OrientationWithZ => AvalonSimulation::StateEstimator

use AvalonControl::MotionControlTask => AvalonControl::MotionControlTask.
  use_conf("default", "simulation")

# add(Cmp::AUVJoystickCommand)
add_mission(AvalonSimulation::Task)


### not finished or tested
