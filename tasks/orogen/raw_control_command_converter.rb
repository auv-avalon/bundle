composition 'AUVJoystickCommand' do
    add Srv::RawCommand, :as => 'rawCommand'
    add RawControlCommandConverter::Movement, :as => 'rawCommandConverter'
    autoconnect

    export rawCommandConverter.motion_command
    provides Srv::AUVMotionCommand
end
