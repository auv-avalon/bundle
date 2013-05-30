class AuvRelPosController::Task
    provides Srv::Command
end

# NOTE: the 'controller' => Bla part of the specialization should not be needed,
# but is as of today (29.05.2011)


##Cmp::ControlLoop.specialize 'controller' => AuvRelPosController::Task do
##    add Srv::OrientationWithZ
##
###    overload 'controller', Srv::AUVMotionController
##    export command.position_command
##    connect orientation_with_z => command
##    connect command => controller
##end
