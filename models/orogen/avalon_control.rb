require 'models/blueprints/avalon_base'

module Avalon
    
    class AvalonControl::FakeWriter
        provides Base::AUVMotionControllerSrv, :as => "controller"
    end

    class AvalonControl::MotionControlTask 
        provides Base::AUVMotionControlledSystemSrv, :as => "controlled"
    end

    Base::ControlLoop.specialize 'controlled_system' => AvalonControl::MotionControlTask do
        add OrientationWithZSrv, :as => 'pose'
        add GroundDistanceSrv, :as => 'dist'
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

