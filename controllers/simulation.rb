require 'controllers/common_controller'

Roby.app.apply_orocos_deployment 'simulation' # load config/deployments/avalon.rb

module Robot
    def self.sim_set_position(x, y, z)
        task = Orocos::TaskContext.get 'avalon_simulation'
        task.setPosition(x, y, z)
    end

    def self.sim_set_pose(x, y, z, yaw)
        task = Orocos::TaskContext.get 'avalon_simulation'
        task.setPosition(x, y, z)
        task.setYaw(yaw)
    end

    def self.sim_set_avalon(object)
        buoy = { :x => 55.0, :y => -1.0, :z => -2.5, :theta => Math::PI / 2.0 }
        pipe = { :x => 0.0, :y => 0.0, :z => -0.0, :theta => 0.0 }
        wall = { :x => 45.0, :y => 2.5, :z => -4.5, :theta => 0.0 }

        position = nil

        case object
        when :buoy
            position = buoy
        when :pipeline
            position = pipe
        when :wall
            position = wall
        else
            position = pipe
        end

        sim_set_pose(position[:x], position[:y], position[:z], position[:theta])
    end
end

module Robot
    def self.emergency_surfacing
        task = Orocos::TaskContext.get('actuators_simulation')
	task.command.disconnect_all
        writer = task.command.writer
        sample = writer.new_sample
        sample.time = Time.now
        sample.mode = [:DM_PWM] * 6
        sample.target = [0, -0.5, 0, 0, 0, 0]
        Roby.each_cycle do |_|
            writer.write(sample)
        end
    end
end

