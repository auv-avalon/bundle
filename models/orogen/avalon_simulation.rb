using_task_library "avalon_simulation"


Dev::Simulation.device_type "Echosounder" do
    provides Base::GroundDistanceSrv
end

#module Dev
#    device_type "Micron" do
#        provides Avalon::SonarScanProviderSrv
#    end
#
#    device_type "Echosounder" do
#        provides Avalon::GroundDistanceSrv
#    end
#
#end

#class Sim
#    driver_for Dev::Micron , :as => 'driver' 
#end

class AvalonSimulation::GroundDistance
    driver_for Dev::Simulation::Echosounder , :as => 'driver'
end

#class SonarTritech::Profiling
#    driver_for "Dev::Profiling"
#end

