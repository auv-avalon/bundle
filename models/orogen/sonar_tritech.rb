class SonarTritech::Micron
    driver_for "Dev::Micron" do
        provides Srv::SonarScanProvider
        provides Srv::GroundDistance
    end
end

class SonarTritech::Echosounder
    driver_for "Dev::Echosounder" do
        provides Srv::GroundDistance
    end
    def configure
       super
    end
end

#class SonarTritech::Profiling
#    driver_for "Dev::Profiling"
#end

