require 'models/blueprints/avalon_base'

module Avalon
    
    class AvalonControl::FakeWriter
        provides Base::AUVMotionControllerSrv, :as => "controller"
    end
    
    class AvalonControl::RelFakeWriter
        provides Base::AUVRelativeMotionControllerSrv, :as => "controller"
    end

    class AvalonControl::MotionControlTask 
#        orogen_model.input_port 'command_in', '/base/actuators/Status'
        provides Base::AUVMotionControlledSystemSrv, :as => "auv_motion_controlled"
        provides Base::ActuatorControllerSrv, :as => "actuator_controller"
    end

    Base::ControlLoop.specialize Base::ControlLoop.controller_child => AvalonControl::MotionControlTask do
        add Base::OrientationWithZSrv, :as => 'pose'
        add Base::GroundDistanceSrv, :as => 'dist'
        connect pose_child.orientation_z_samples_port => controller_child.pose_samples_port
        connect dist_child.distance_port => controller_child.ground_distance_port
    end
end

#Cmp::ControlLoop.specialize 'controller' => AvalonControl::PositionControlTask do
#    add Srv::Pose
#    autoconnect
#end

