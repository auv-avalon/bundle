
use DataServices::Orientation => AvalonSimulation::StateEstimator
add_mission(AvalonSimulation::Task)
add_mission(Cmp::ControlLoop).use(Cmp::PipelineFollower.use('bottom_camera'))

