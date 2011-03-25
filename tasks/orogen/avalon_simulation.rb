class AvalonSimulation::Task 
    provides Srv::Orientation
    bla_l = driver_for('Simulator')
    bla    = bla_l.dynamic_slaves 'Simulation' do
      #  output_port "errors_#{name}", "/hbridge/Error"
        input_port  "cmd_#{name}",    "/base/actuators/Command"
       # output_port "status_#{name}", "/base/actuators/Status"
        provides Srv::Actuators, "command" => "cmd_#{name}"
    end

    def configure
        super
	orogen_task.enable_gui = true
	orogen_task.with_manipulator_gui = true
    end
end
