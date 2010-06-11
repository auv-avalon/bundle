using_task_library 'avalon_control'
using_task_library 'motcon_controller'
composition 'AUVControlLoop' do
    add AUVDriver, :as => 'driver'
    add Pose
    add AvalonControl::MotionControlTask
    add MotconController::MotconControllerTask
    autoconnect
end

