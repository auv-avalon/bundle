class AuvRelPosController::Task
    provides Srv::Command
end

# NOTE: the 'controller' => Bla part of the specialization should not be needed,
# but is as of today (29.05.2011)
Cmp::ControlLoop.specialize 'command' => AuvRelPosController::Task do
    add Srv::OrientationWithZ

    overload 'controller', Srv::AUVMotionController
    export command.position_command
    # connect command.motion_command => controller.command
    
    autoconnect
end
