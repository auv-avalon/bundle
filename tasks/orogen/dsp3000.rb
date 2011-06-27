class Dsp3000::Task 
    driver_for "Dsp3000"
    def configure
        super
        robot_def = robot_device
        period = (robot_def.period * 1000).round
        #orogen_task.device_period = period
    end
end

