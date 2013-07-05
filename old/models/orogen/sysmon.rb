class Sysmon::Task
    driver_for 'ExperimentMarkers'
    driver_for 'SystemStatus'

    on :start do |event|
        @system_status = data_reader :system_status
    end

    poll do
        if !@system_status.nil?
            if sample = @system_status.read
                ::State.lowlevel_state = sample.systemState
	        ::State.lowlevel_substate = sample.systemSubstate
            end
        end
    end
end

