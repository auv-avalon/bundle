require "models/blueprints/auv"

using_task_library "canbus"

module Dev
    module Sensors
        device_type "Battery" do
            provides Dev::Bus::CAN::ClientInSrv
        end
    end
end


class BatteryWatcher::Task
    driver_for Dev::Sensors::Battery, :as => "task"
    on :start do |event|
        @reader = data_reader :battery_info
        ::State.lowest_cell = 0 
    end

    poll do
        if !@system_status.nil?
            if sample = @system_status.read
                ::State.lowest_cell = sample.cell_voltage0
                ::State.lowest_cell = sample.cell_voltage1 if sample.cell_voltage1 < ::State.lowest_cell
                ::State.lowest_cell = sample.cell_voltage2 if sample.cell_voltage2 < ::State.lowest_cell
                ::State.lowest_cell = sample.cell_voltage3 if sample.cell_voltage3 < ::State.lowest_cell
                ::State.lowest_cell = sample.cell_voltage4 if sample.cell_voltage4 < ::State.lowest_cell
                ::State.lowest_cell = sample.cell_voltage5 if sample.cell_voltage5 < ::State.lowest_cell
                ::State.lowest_cell = sample.cell_voltage6 if sample.cell_voltage6 < ::State.lowest_cell
                ::State.lowest_cell = sample.cell_voltage7 if sample.cell_voltage7 < ::State.lowest_cell
            end
        end
    end
end
    
