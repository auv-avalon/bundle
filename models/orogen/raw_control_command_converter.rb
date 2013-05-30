load_system_model 'blueprints/avalon_base'



composition 'AUVJoystickCommand' do
    add Srv::RawCommand, :as => 'rawCommand'
    add Srv::OrientationWithZ, :as => 'orientation_with_z'
    add RawControlCommandConverter::Movement, :as => 'rawCommandConverter'
    add Srv::GroundDistance, :as => 'dist'
    connect dist.distance => rawCommandConverter.ground_distance
    connect orientation_with_z.orientation_z_samples => rawCommandConverter
    autoconnect

    export rawCommandConverter.motion_command
    export rawCommandConverter.world_command, :as => "WorldCommand"
    export rawCommandConverter.aligned_velocity_command, :as =>"VeloCommand"
    
    provides Srv::AUVMotionController
    #provides Srv::Raw6DWorldCommand#, "world_command" => "WorldCommand"
    #provides Srv::Raw6DVeloCommand
    
#    provides Srv::LinearAngular6DCommand
#    provides Srv::LinearAngular6DCommand
end

