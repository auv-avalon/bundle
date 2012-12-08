class AvalonSimulation::Task
    def configure
        autoproj = ENV['AUTOPROJ_PROJECT_BASE']

        file = "avalon.scn"

        task = Orocos::TaskContext.get self.orocos_name
        task.scenefile = File.join(autoproj, 
                                   "simulation",
                                   "orogen",
                                   "avalon_simulation",
                                   "configuration",
                                   file)
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

class AvalonSimulation::TopCamera
    driver_for Dev::MarsCamera
end

class AvalonSimulation::SonarTop
    driver_for 'Dev::MarsSonar'
    provides Srv::SonarScanProvider
end


class AvalonSimulation::SonarRear
    driver_for 'Dev::MarsSonarBottom'
    provides Srv::SonarScanProvider
    provides Srv::GroundDistance
end


class AvalonSimulation::Modem
    driver_for 'Dev::MarsModem'
    provides Srv::ModemConnection
end


class AvalonSimulation::Actuators
    driver_for 'Dev::MarsAvalonThrusters'
    provides Srv::Actuators
end

class AvalonSimulation::PingerSearch
    provides Srv::SoundSourceDirection
end

class AvalonSimulation::StateEstimator
    provides Srv::Pose
    provides Srv::Speed
end
