using_task_library "controldev"
require 'models/blueprints/avalon_base'

module Avalon
    class AUVJoystickCommand < Syskit::Composition 
        add Base::RawCommandControllerSrv, :as => 'rawCommand'
        add Base::OrientationWithZSrv, :as => 'orientation_with_z'
        add RawControlCommandConverter::Movement, :as => 'rawCommandConverter'
        add Base::GroundDistanceSrv, :as => 'dist'
        connect dist_child.distance_port => rawCommandConverter_child.ground_distance_port
        connect orientation_with_z_child.orientation_z_samples_port => rawCommandConverter_child.orientation_readings_port
        #TODO Check autoconnect
#        autoconnect

        export rawCommandConverter_child.motion_command_port
        export rawCommandConverter_child.world_command_port, :as => "WorldCommand"
        export rawCommandConverter_child.aligned_velocity_command_port, :as =>"VeloCommand"
        
        #TODO Change this to an ControlLoop
        provides Base::AUVMotionControllerSrv, :as => "controller"

        #provides Srv::Raw6DWorldCommand#, "world_command" => "WorldCommand"
        #provides Srv::Raw6DVeloCommand
        
    #    provides Srv::LinearAngular6DCommand
    #    provides Srv::LinearAngular6DCommand
    end

end
