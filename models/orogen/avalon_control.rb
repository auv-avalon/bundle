load_system_model 'blueprints/avalon_base'

class AvalonControl::MotionControlTask 
    provides Srv::AUVMotionControlledSystem
end

Cmp::ControlLoop.specialize 'controlled_system' => AvalonControl::MotionControlTask do
    add Srv::OrientationWithZ, :as => 'pose'
    add Srv::GroundDistance, :as => 'dist'
    add Srv::ActuatorControlledSystem, :as => "sub_controller"
    connect pose.orientation_z_samples => controlled_system.pose_samples
    connect dist.distance => controlled_system.ground_distance
    connect controlled_system => sub_controller 
   autoconnect 
end

#Cmp::ControlLoop.specialize 'controller' => AvalonControl::PositionControlTask do
#    add Srv::Pose
#    autoconnect
#end

