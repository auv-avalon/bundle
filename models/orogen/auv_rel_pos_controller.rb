class AuvRelPosController::Task
	provides Srv::AUVRelativeMotionControlledSystem
	provides Srv::AUVMotionController
end

# NOTE: the 'controller' => Bla part of the specialization should not be needed,
# but is as of today (29.05.2011)
Cmp::ControlLoop.specialize 'controlled_system' => AuvRelPosController::Task do
    add Srv::OrientationWithZ
#    add AvalonControl::MotionControlTask, :as => "auvmotion"
    
    
    #workaround
    add Srv::OrientationWithZ, :as => 'pose'
    add Srv::GroundDistance, :as => 'dist'
    add Srv::ActuatorControlledSystem, :as => "sub_controller"
    add AvalonControl::MotionControlTask, :as => "motion"
    autoconnect

#    connect pose.orientation_z_samples => controlled_system.pose_samples
#    connect dist.distance => controlled_system.ground_distance
#    connect controlled_system => sub_controller 
    
    #end workaround

    ###should work but does not so adding everything manually
#    add Srv::AUVMotionControlledSystem, :as => "auvmotion"
    
    
    #add Srv::ActuatorController, :as => "act_controller"
    #add Srv::ActuatorControlledSystem, :as => "sub_controller" #this should not be needed but recursion seems not to work on bundles correct

#    overload 'controller', Srv::AUVMotionController
#    export controlles_system.position_command
    connect orientation_with_z => controlled_system
#    connect command => controlles_system 
#    connect controlled_system => auvmotion
#    connect act_controller => sub_controller
 #  autoconnect 

end
