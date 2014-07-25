require "models/profiles/avalon_simulation/main.rb"
require "models/profiles/main.rb"
require "models/blueprints/auv"
require "models/blueprints/pose_avalon"

using_task_library 'simulation'
using_task_library 'avalon_simulation'


module Avalon

    module Profiles
        profile "SimulationFast" do
            use_profile Simulation

            define 'sim', ::AvalonSimulation::Task
            define 'trigger', ::Simulation::MarsTrigger
            define 'sched', ::TaskScheduler::Task
        end
    end
end

