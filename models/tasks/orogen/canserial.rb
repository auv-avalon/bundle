class Canserial::Task
    canserial = driver_for 'CanSerial'
    gpios = canserial.dynamic_slaves 'GPIOWatch'

    canserial.dynamic_slaves 'GPIOWatchFE' do
        output_port "f#{name}", "/base/Time"
        provides Srv::HWTimestamp, 'timestamps' => "f#{name}"
    end
    canserial.dynamic_slaves 'GPIOWatchRE' do
        output_port "r#{name}", "/base/Time"
        provides Srv::HWTimestamp, 'timestamps' => "r#{name}"
    end

    gpios.extend_device_configuration do
        dsl_attribute 'pin' do |value|
            value = value.to_str
            if value !~ /^[A-D][0-3]$/
                raise ArgumentError, "invalid pin specification #{value}, valid pins are A0 to A3, B0 to B3, C0 to C3 and D0 to D3"
            end
            value
        end

        def on_falling_edge(name)
            @on_falling_edge = true
            master_device.slave(Devices::GPIOWatchFE, :as => name)
            self
        end
        def on_rising_edge(name)
            @on_rising_edge = true
            master_device.slave(Devices::GPIOWatchRE, :as => name)
            self
        end

        def pull_none; @pull = 'PullNone'; self end
        def pull_up;   @pull = 'PullUp';   self end
        def pull_down; @pull = 'PullDown'; self end

        def pull_mode
            @pull_mode || 'PullNone'
        end

        def edge_mode
            if @on_falling_edge && @on_rising_edge
                'RisingFallingEdge'
            elsif @on_falling_edge
                'FallingEdge'
            elsif @on_rising_edge
                'RisingEdge'
            else
                raise ArgumentError, "you have to specify on which edge should the GPIO input be triggered"
            end
        end
    end

    uarts = canserial.dynamic_slaves 'UART' do
        output_port name, "/canserial/UartInput"
        input_port  "w#{name}", "/canserial/UartOutput"
    end
    uarts.extend_device_configuration do
        dsl_attribute 'uart' do |value|
            id = Integer(value)
            if id < 1 || value > 3
                raise ArgumentError, "UART ID should be between 1 and 3"
            end
            id
        end

        dsl_attribute 'stop_bits' do |value|
            value = Integer(value)
            if value != 1 && value != 2
                raise ArgumentError, "supports only one or two stop bits"
            end
            value
        end

        attr_reader :parity
        def no_parity;   @parity = 'NoParity'   ; self end
        def even_parity; @parity = 'EvenParity' ; self end
        def odd_parity;  @parity = 'OddParity'  ; self end

        dsl_attribute 'baud_rate' do |value|
            Integer(value)
        end
        def enable_tx;   @enable_tx = true; self end
        def disable_tx;  @enable_tx = false; self end
        def tx_enabled?; @enable_tx.nil? || @enable_tx end
        def enable_rx;   @enable_rx = true; self end
        def disable_rx;  @enable_rx = false; self end
        def rx_enabled?; @enable_rx.nil? || @enable_rx end
    end

    def configure
        super

        # WARNING: the watches can be set in configure() but the triggers have to be
        # WARNING: set in start
        each_slave_device 'can_serial', Orocos::RobyPlugin::Devices::GPIOWatch do |slave_name, slave_device|
            if !slave_device.pin
                raise ArgumentError, "no pin given in configuration of #{slave_device.name}"
            end

            Robot.info "canserial: creating GPIO watch #{slave_device.name} for pin #{slave_device.pin}"
            Robot.info "canserial:  watch_gpio(#{slave_device.name}, Pin_#{slave_device.pin}, #{slave_device.edge_mode}, #{slave_device.pull_mode})"
            result = orogen_task.watch_gpio(slave_device.name,
                    "Pin_#{slave_device.pin}", slave_device.edge_mode, slave_device.pull_mode)
            if !result
                raise ArgumentError, "cannot create GPIO watch #{slave_device.name} for pin #{slave_device.pin}"
            end
        end
    end
        
    on :start do |event|
        # WARNING: the watches can be set in configure() but the triggers have to be
        # WARNING: set in start
        canserial_config = Orocos.registry.get('/canserial/GpioOutConfig').new
        canserial_config.level1 = "Low" #0
        canserial_config.level2 = "High" #1
        canserial_config.time1 =  10000
        canserial_config.time2 = 990000
        canserial_config.denominator = 5 #effectively frequency in Hz
        orogen_task.configure_gpio_periodic("Pin_D1", canserial_config);
        orogen_task.start_gpio("Pin_D1", Time.now + 3)
    end
end

