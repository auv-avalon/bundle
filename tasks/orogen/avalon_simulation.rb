class AvalonSimulation::Task
    def configure
        autoproj = ENV['AUTOPROJ_PROJECT_BASE']

        task = Orocos::TaskContext.get self.orocos_name
        task.scenefile = File.join(autoproj, 
                                   "simulation",
                                   "orogen",
                                   "avalon_simulation",
                                   "configuration",
                                   "studiobad.scn")
        Orocos.apply_conf_file(task, File.join(autoproj,
                                               "supervision",
                                               "config",
                                               "orogen",
                                               "avalon_simulation::Task.yml"))
    end
end

device_type 'MarsCamera' do
    provides Srv::ImageProvider
end


class AvalonSimulation::BottomCamera
    driver_for Dev::MarsCamera
end


class AvalonSimulation::FrontCamera
    driver_for Dev::MarsCamera
end


class AvalonSimulation::SonarTop
    driver_for 'MarsSonar'
    provides Srv::SonarScanProvider
end


#class AvalonSimulation::SonarBottom
#    driver_for 'MarsSonarBottom'
#    provides Srv::SonarScanProvider    
#end


class AvalonSimulation::Actuators
    driver_for 'MarsAvalonThrusters'
    provides Srv::Actuators
end


class AvalonSimulation::StateEstimator
    provides Srv::Pose
end
