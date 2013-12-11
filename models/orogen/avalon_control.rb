require 'models/blueprints/avalon'

class AvalonControl::FakeWriter
    attr_reader :options

    def configure
        super
        return if(!@options)
        update_config(@options)
    end

    def update_config(options)
        @options = options
        STDOUT.puts "Starting real task with options: #{@options}"
        orocos_task.speed_x = @options[:speed_x] if @options[:speed_x]
        orocos_task.speed_y = @options[:speed_y] if @options[:speed_y]
        orocos_task.Z = @options[:depth] if @options[:depth]
        orocos_task.heading = @options[:heading] if @options[:heading]
    end


        
    provides Base::AUVMotionControllerSrv, :as => "controller"
end

class AvalonControl::RelFakeWriter
    attr_reader :options

    def configure
        super
        return if(!@options)
        update_config(@options)
    end

    def update_config(options)
        @options = options
        STDOUT.puts "Starting real Poisitioning task with options: #{@options}"
        orocos_task.x = @options[:x] if @options[:x]
        orocos_task.y = @options[:y] if @options[:y]
        orocos_task.z = @options[:depth] if @options[:depth]
        orocos_task.heading = @options[:heading] if @options[:heading]
    end
    provides Base::AUVRelativeMotionControllerSrv, :as => "controller"
end

class AvalonControl::MotionControlTask 
    provides Base::AUVMotionControlledSystemSrv, :as => "auv_motion_controlled"
    provides Base::ActuatorControllerSrv, :as => "actuator_controller"
     
end

