class SonarTritech::Micron
    driver_for "Dev::Micron" do
        provides Srv::SonarScanProvider
    end
end

class SonarTritech::Profiling
    driver_for "Dev::Profiling"
end

