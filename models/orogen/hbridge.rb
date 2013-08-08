module Dev
    device_type "Hbridge" do
        #provides Base::ZProviderSrv
        provides Dev::Bus::CAN::ClientInSrv
        provides Dev::Bus::CAN::ClientOutSrv
    end
end


class Hbridge::Task
        driver_for Dev::Hbridge, :as => "driver"
        
        def hui
            "hfisdh"
        end
    
        def self.dispatch(name, mappings)
            model = self.specialize
            model.require_dynamic_service('dispatch', :as => name, :mappings => mappings)
            model 
        end
        
        dynamic_service  Base::ActuatorControlledSystemSrv, :as => 'dispatch' do
            #provides Dev::Bus::CAN::ClientInSrv
            component_model.argument "#{name}_mappings", :default => options[:mappings]
            provides  Base::ActuatorControlledSystemSrv, "status_out" => "status_#{name}", "command_in" => "cmd_#{name}"
        end

#        forward :timeout => :failed
#        on :timeout do
#            orocos_task.stop
#            orocos_task.start
#        end

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
