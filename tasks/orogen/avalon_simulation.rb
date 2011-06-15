#load_system_model 'tasks/compositions/base'


#bottom camera task
class AvalonSimulation::BottomCamera
    driver_for 'Dev::BottomCameraSimulation' do
        provides Srv::ImageProvider 
    end
end

#simulator task
class AvalonSimulation::Task 
    def configure
        super
	orogen_task.enable_gui = true
	orogen_task.with_manipulator_gui = true
    end
end

#state estimator 
class AvalonSimulation::StateEstimator
    provides Srv::Orientation
end

class AvalonSimulation::MotionControl
end
