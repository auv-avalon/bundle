require 'models/blueprints/avalon_base'

module Avalon
    
    class AvalonControl::FakeWriter
        provides Base::AUVMotionControllerSrv, :as => "controller"
    end

    class AvalonControl::MotionControlTask 
        provides Base::AUVMotionControlledSystemSrv, :as => "controlled"
    end

    Base::ControlLoop.specialize Base::ControlLoop::controlled_system_child => AvalonControl::MotionControlTask do
        add Base::OrientationWithZSrv, :as => 'pose'
        add Base::GroundDistanceSrv, :as => 'dist'
        add Base::ActuatorControlledSystemSrv, :as => "sub_controller"
        connect pose_child.orientation_z_samples_port => controlled_system_child.pose_samples_port
        connect dist_child.distance_port => controlled_system_child.ground_distance_port
        connect controlled_system_child => sub_controller_child
        #TODO check connection
    end

end

#Cmp::ControlLoop.specialize 'controller' => AvalonControl::PositionControlTask do
#    add Srv::Pose
#    autoconnect
#end

