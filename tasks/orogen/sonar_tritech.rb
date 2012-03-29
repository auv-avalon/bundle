class SonarTritech::Micron
    driver_for "Dev::Micron" do
        provides Srv::SonarScanProvider
        provides Srv::ZProvider
    end
end

#class SonarTritech::Profiling
#    driver_for "Dev::Profiling"
#end

