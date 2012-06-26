composition 'AUVJoystickCommand' do
    add Srv::RawCommand, :as => 'rawCommand'
    add Srv::OrientationWithZ
    add RawControlCommandConverter::Movement, :as => 'rawCommandConverter'
    add Srv::GroundDistance, :as => 'dist'
    connect dist.distance => rawCommandConverter.ground_distance
    autoconnect

    export rawCommandConverter.motion_command
    provides Srv::AUVMotionCommand
end

