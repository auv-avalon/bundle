class SonarDriver::Micron
    driver_for "Dev::Micron" do
        provides Srv::SonarScanProvider
    end
end

class SonarDriver::Profiling
    driver_for "Dev::Profiling"
end

