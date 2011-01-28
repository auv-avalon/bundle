class Sysmon::Task
    driver_for 'ExperimentMarkers'
    driver_for 'SystemStatus'
    driver_for 'LEDSignal'

    on :start do |event|
        @system_status = data_reader :system_status
    end

    poll do
        if sample = @system_status.read
            ::State.lowlevel_state = sample.systemState
        end
    end
end

