# This is separated from Controller as other type of control exist in the
# components (as for instance FourWheelController in controldev)

load_system_model 'blueprints/visual_servoing'
load_system_model 'blueprints/control'
load_system_model 'blueprints/avalon_base'


using_task_library 'auv_rel_pos_controller'
using_task_library 'auv_waypoint_navigator'
using_task_library 'avalon_control'



composition 'VisualServoing' do
    add Srv::RelativePositionDetector, :as => 'detector'
    #add(Cmp::ControlLoop, :as => 'control').
    add(Srv::AUVMotionControlledSystem, :as => 'control')
    add(AuvRelPosController::Task, :as => 'rel-controller')


    export control.command_in

    
#      use('command_in' => AuvRelPosController::Task).
#      use('controller' => AvalonControl::MotionControlTask) 

    autoconnect
end


