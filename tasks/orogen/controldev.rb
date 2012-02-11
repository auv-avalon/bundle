data_service_type 'FourWheelController' do
    provides Srv::ActuatorController
    input_port 'command', 'controldev/FourWheelCommand'
end

data_service_type 'FourWheelCommand' do
    provides Srv::Command
    output_port 'command', 'controldev/FourWheelCommand'
end





device_type 'RemoteJoystick' do
    provides Srv::Motion2DCommand
    provides Srv::RawCommand
end
device_type 'RemoteSliderbox' do
    provides Srv::FourWheelCommand
end
device_type 'Joystick' do
    provides Srv::Motion2DCommand
    provides Srv::RawCommand
end



class Controldev::Remote
    driver_for Dev::RemoteJoystick, :as => 'joystick'
    # driver_for Dev::RemoteSliderbox, :as => 'sliderbox'
end

class Controldev::JoystickTask
    driver_for Dev::Joystick
end

Compositions::ControlLoop.
    specialize Srv::ActuatorController => Srv::FourWheelController, Srv::Command => Srv::FourWheelCommand do
        autoconnect
    end

