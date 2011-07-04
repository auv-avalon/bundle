require 'controllers/common_controller'
Roby.app.apply_orocos_deployment 'simulation' # load config/deployments/avalon.rb

module Robot
    def self.sim_set_position(x, y, z)
        task = Orocos::TaskContext.get 'avalon_simulation'
        task.setPosition(x, y, z)
    end
end

