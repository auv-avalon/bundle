composition 'AUVJoystickCommand' do
    add Srv::RawCommand, :as => 'rawCommand'
    add Srv::OrientationWithZ, :as => 'orientation_with_z'
    add RawControlCommandConverter::Movement, :as => 'rawCommandConverter'
    add Srv::GroundDistance, :as => 'dist'
    connect dist.distance => rawCommandConverter.ground_distance
    connect orientation_with_z.orientation_z_samples => rawCommandConverter
    autoconnect

    export rawCommandConverter.motion_command
    provides Srv::AUVMotionCommand
end

