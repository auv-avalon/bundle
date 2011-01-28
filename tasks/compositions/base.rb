composition 'ControlLoop' do
    abstract

    add Actuators
    add ActuatorController, :as => 'controller'
    add Command

    # Specialize for the controller types that are defined in base
    specialize 'controller' => Motion2DController, 'command' => Motion2DCommand
    autoconnect
end

