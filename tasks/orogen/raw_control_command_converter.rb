composition 'AUVJoystickCommand' do
    add Srv::RawCommand, :as => 'rawCommand'
    add Srv::OrientationWithZ
    add RawControlCommandConverter::Movement, :as => 'rawCommandConverter'
    autoconnect

    export rawCommandConverter.motion_command
    provides Srv::AUVMotionCommand
end

Cmp::ControlLoop.specialize 'command' => Cmp::AUVJoystickCommand do

    overload 'controller', Srv::AUVMotionController
    export command.motion_command
    # connect command.motion_command => controller.command
    autoconnect
end
