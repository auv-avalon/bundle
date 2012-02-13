#load_system_model 'tasks/compositions/main'

class Hbridge::Task
    hbridge_set = driver_for('HbridgeSet')
    hbridges    = hbridge_set.dynamic_slaves 'Hbridges' do
        output_port "errors_#{name}", "/hbridge/Error"
        input_port  "cmd_#{name}",    "/base/actuators/Command"
        output_port "status_#{name}", "/base/actuators/Status"
        provides Srv::Actuators, "status" => "status_#{name}", "command" => "cmd_#{name}"
    end

    hbridges.extend_device_configuration do
        dsl_attribute :select_ids do |*args|
            args.map do |i|
                i = Integer(i)
                if i.abs > 7
                    raise ArgumentError, "invalid motor value #{i}, must be in [-7, 7]"
                end
                i
            end
        end
        def read_only; @read_only = true end
        def read_only?; !!@read_only end
    end

    BOARD_TIMEOUT = 1
    def configure
        super
        
        # Set timeout and static external encoder calibration
        current_config = orogen_task.configuration
        6.times do |i|
            current_config.config[i].base_config.timeout = Integer(BOARD_TIMEOUT * 1000)
        end
        orogen_task.configuration = current_config

        # We do an encoder calibration each time the module is started
        #orogen_task.do_encoder_calibration = true

        # Create dispatchers
        each_slave_device('hbridge_set') do |slave_service, slave_device|
            Robot.info "hbridge: dispatching #{slave_device.select_ids} on #{slave_device.name} [#{slave_device.read_only? ? "RO" : "RW"}]"
            if !orogen_task.dispatch(slave_device.name, slave_device.select_ids, slave_device.read_only?)
                raise ArgumentError, "cannot create dispatch #{slave_device.name}: #{slave_device.select_ids}"
            end
        end
    end

    event :read_only
    forward :runtime_error => :read_only

    event :read_write
    forward :running => :read_write
end


