require 'controllers/common_controller'
Roby.app.apply_orocos_deployment 'simulation' # load config/deployments/avalon.rb

module Robot
    def self.sim_set_position(x, y, z)
        task = Orocos::TaskContext.get 'avalon_simulation'
        task.setPosition(x, y, z)
    end

    def self.set_avalon_to(object)
        buoy = { :x => 59.0, :y => -8.0, :z => -7.5, :theta => Math::PI }
        pipe = { :x => 30.0, :y => -5.0, :z => -2.5, :theta => Math::PI }
        wall = { :x => 70.0, :y => 10.0, :z => -4.5, :theta => Math::PI }

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

