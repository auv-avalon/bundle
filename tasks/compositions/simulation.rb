using_task_library "avalon_simulation"

composition 'ControlLoopSimulation' do
    #basic tasks simulator
    add AvalonSimulation::Task
    add AvalonSimulation::MotionControl, :as => "control"
    add Srv::Orientation, :as => "pose"

    add Srv::AUVMotionCommand
    autoconnect
end


