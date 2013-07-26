require 'models/blueprints/avalon_base'

class AuvRelPosController::Task
    provides Base::AUVRelativeMotionControlledSystemSrv, :as => "controlled_system"
    provides Base::AUVMotionControllerSrv, :as => "controller"
end

Base::ControlLoop.specialize Base::ControlLoop::controller_child => AuvRelPosController::Task do
    add Base::OrientationWithZSrv, :as => "orientation_with_z"
    orientation_with_z_child.connect_to controller_child
end






















    #workaround
#    add OrientationWithZSrv, :as => 'pose'
#    add GroundDistanceSrv, :as => 'dist'

    #add ActuatorControlledSystemSrv, :as => "sub_controller"
    #add ActuatorControlledSystemSrv, :as => "sub_controller"
    #add AvalonControl::MotionControlTask, :as => "motion"
    #autoconnect
    #TODO DO CONNECTION

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
 #   connect orientation_with_z_child => controlled_system_child
#    connect command => controlles_system_child
#    connect controlled_system => auvmotion
#    connect act_controller => sub_controller
 #  autoconnect 

#end
