data_service_type 'FourWheelController', :provides => ActuatorController do
    input_port 'command', 'controldev/FourWheelCommand'
end

data_service_type 'FourWheelCommand', :provides => Command do
    output_port 'command', 'controldev/FourWheelCommand'
end

device_type 'RemoteJoystick', :provides => Motion2DCommand
device_type 'RemoteSliderbox', :provides => FourWheelCommand
device_type 'Joystick', :provides => Motion2DCommand

class Controldev::Remote
    driver_for RemoteJoystick, :as => 'joystick'
    driver_for RemoteSliderbox, :as => 'sliderbox'
end

class Controldev::Local
    driver_for Joystick
    def configure
        super

        orogen_task.minSpeed = 0.1
        orogen_task.maxSpeed = 1.5
        orogen_task.maxRotationSpeed = 3.14
    end
end

Compositions::ControlLoop.
    specialize ActuatorController => FourWheelController, Command => FourWheelCommand do
        autoconnect
    end

