require 'controllers/common_controller'
Roby.app.apply_orocos_deployment 'simulation' # load config/deployments/avalon.rb

module Robot
    def self.sim_set_position(x, y, z)
        task = Orocos::TaskContext.get 'avalon_simulation'
        task.setPosition(x, y, z)
    end

    def self.set_robot_to_buoy
        sim_set_position(37.0, -8.0, -7.5)
    end

    def self.set_robot_to_pipeline
        sim_set_position(15.0, -5.0, -4.5)
    end
end

