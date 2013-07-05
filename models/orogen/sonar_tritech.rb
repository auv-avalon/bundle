module Dev
    device_type "Micron" do
        provides Avalon::SonarScanProviderSrv
        provides Avalon::GroundDistanceSrv  
    end

    device_type "Echosounder" do
        provides Avalon::GroundDistanceSrv
    end

    device_type "Profiling"
end

class SonarTritech::Micron
    driver_for Dev::Micron , :as => 'driver' 
end

class SonarTritech::Echosounder
    driver_for Dev::Echosounder , :as => 'driver'
end

#class SonarTritech::Profiling
#    driver_for "Dev::Profiling"
#end

