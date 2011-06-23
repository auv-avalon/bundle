class AvalonSimulation::Task 
#    provides Srv::Orientation
#    task = driver_for('Simulator')
    
#    control = task.dynamic_slaves 'SimulatorControl' do
        #output_port "errors_#{name}", "/hbridge/Error"
#        input_port  "cmd_#{name}",    "/base/actuators/Command"
#        output_port "status_#{name}", "/base/actuators/Status"
#        provides Srv::Actuators, "status" => "status_#{name}", "command" => "cmd_#{name}"
#    end

    def configure
        super
	orogen_task.enable_gui = true
	orogen_task.with_manipulator_gui = true
#    
#        # Create dispatchers
#        if !orogen_task.dispatch("simulator_control", [0,1,2,3,4,5], false)
#            raise ArgumentError, "cannot create dispatch #{slave_device.name}: #{slave_device.select_ids}"
#        end
    end
end

class AvalonSimulation::BottomCamera
  driver_for Dev::Camera
end

class AvalonSimulation::FrontCamera
  driver_for Dev::Camera
end

class AvalonSimulation::Actuators
  provides Srv::Actuators
end

