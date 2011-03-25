composition 'ControlLoop' do
    abstract

    add Srv::Actuators
    add Srv::ActuatorController, :as => 'controller'
    add Srv::Command

    # Specialize for the controller types that are defined in base
    specialize 'controller' => Srv::Motion2DController, 'command' => Srv::Motion2DCommand
    autoconnect
end

composition 'ControlLoopGeneric' do
    abstract

    add Srv::Actuators
    add Srv::ActuatorController, :as => 'controller'
    add Srv::Command

    # Specialize for the controller types that are defined in base
    specialize 'controller' => Srv::Motion2DController, 'command' => Srv::Motion2DCommand
    autoconnect
end


