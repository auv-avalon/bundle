require 'controllers/common_controller'
Roby.app.apply_orocos_deployment 'simulation' # load config/deployments/avalon.rb

module Robot
    def self.sim_set_position(x, y, z)
        task = Orocos::TaskContext.get 'avalon_simulation'
        task.setPosition(x, y, z)
    end

    def self.set_avalon_to(object)
        buoy = { :x => 55.0, :y => -1.0, :z => -2.5, :theta => Math::PI / 2.0 }
        pipe = { :x => 0.0, :y => 0.0, :z => -0.0, :theta => 0.0 }
        wall = { :x => 58.0, :y => 2.5, :z => -4.5, :theta => Math::PI / 2.0 }

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

        sim_set_position(position[:x], position[:y], position[:z])
    end
end

