load_system_model 'tasks/compositions/base'

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

require 'roby/tasks/timeout'
Compositions::ControlLoop.specialize 'actuators' => Hbridge::Task do
    add Hbridge::Task, :as => 'actuators',
        :consider_in_pending => false,
        :failure => [:read_only.not_followed_by(:read_write), :stop]

    on :start do |ev|
        hbridge = child_from_role 'actuators'

        # When we start the control composition, disable error handling for the
        # hbridge for 10 seconds in order to wait for it to do its calibration
        # and/or simply the read_only to read_write switch
        timeout = Roby::Tasks::Timeout.new(:delay => 10)
        timeout.on(:start) { |ev| Robot.info "delaying read_only errors by #{timeout.delay} seconds" }
        timeout.on(:timed_out)  { |ev| Robot.info "timed out on read_only to read_write switch, resuming handling of hbridge errors" }
        hbridge.read_only_event.handle_with(timeout)
        timeout.start!

      Robot.info "hb is of class #{hbridge.class}"

        Robot.info  "timout started"
        # But resume error handling as soon as read_write is emitted
        hbridge.read_write_event.on do |event|
            Robot.info "Event: #{event} is calles"
            Robot.info "hbridge switched to read_write, resuming handling of hbridge errors"
        end
        hbridge.read_write_event.signals timeout.stop_event
    end
end

