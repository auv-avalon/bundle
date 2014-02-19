module Dev
    device_type "Hbridge" do
        provides Dev::Bus::CAN::ClientInSrv
        provides Dev::Bus::CAN::ClientOutSrv
    end
end


class Hbridge::Task
        driver_for Dev::Hbridge, :as => "driver"
        worstcase_processing_time 0.2

        def self.dispatch(name, mappings)
            model = self.specialize
            model.require_dynamic_service('dispatch', :as => name, :mappings => mappings)
            model 
        end
        
        dynamic_service  Base::ActuatorControlledSystemSrv, :as => 'dispatch' do
            component_model.argument "#{name}_mappings", :default => options[:mappings]
            provides  Base::ActuatorControlledSystemSrv, "status_out" => "status_#{name}", "command_in" => "cmd_#{name}"
        end

        on :timeout do |ev|
            Robot.error "############################# Hbridges went into timeout ##############################"
            emit :failed
        end
        on :dual_hb_control do |ev|
            Robot.error "########################## Hbridges get an DUAL HB Control ############################"
            emit :failed
        end
        #
#        forward :timeout => :failed
#        forward :dual_hb_control => :failed

        def configure
            each_data_service do |srv|
                if srv.fullfills?(Base::ActuatorControlledSystemSrv)
                    mappings = arguments["#{srv.name}_mappings"]
                    if !orocos_task.dispatch(srv.name, [6, 3, 2, -1, 4, 5],false)
                        puts "Could not dispatch the actuator set #{srv.name}"
                    end
                end
            end
            super
        end
end
