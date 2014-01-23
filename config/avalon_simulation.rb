#Syskit.conf.use_deployment 'avalon_simulation'
Syskit.conf.use_deployment 'AvalonSimulation'
Syskit.conf.use_deployment 'avalon_control_simulation'
Syskit.conf.use_deployment 'pipeline_follower'
Syskit.conf.use_deployment 'wall_servoing'
Syskit.conf.use_deployment 'sonar_feature_estimator'
Syskit.conf.use_deployment 'sonar_wall_hough'
Syskit.conf.use_deployment 'uw_particle_localization'
Syskit.conf.use_deployment 'auv_waypoint_navigator'
Syskit.conf.use_deployment 'asv_detector'
Syskit.conf.use_deployment 'buoy_detector'
Syskit.conf.use_deployment 'pingersearch'

Syskit.conf.disable_logging
Syskit.conf.disable_conf_logging


module Avalon 
    class ShellInterface < Roby::Interface::CommandLibrary

        def set_state(state, substate)
            State.lowlevel_state = state
            State.lowlevel_substate = substate
        end
        command :set_state, "set the current runstate for Avalon as state,substate pair",
            :state => "The given State (0=> off, 3=> autonomous)",
            :substate => "The given substate"

        def tester
            STDOUT.puts "hallo test funktion"
        end
        command :tester, "This tests this module"

        def sim_set_position(x, y, z)
            task = Orocos::TaskContext.get 'avalon'
            task.position = [x, y, z]
        end

        def sim_set_pose(x, y, z, yaw)
            task = Orocos::TaskContext.get 'avalon'
            task.position = Eigen::Vector3.new(x, y, z)
            o = Eigen::Quaternion::from_yaw(yaw)
            task.orientation = o 
        end
#
#    # supply waypoints in this format: [[x1,y1],[x2,y2],...,[xn,yn]]
#    def self.sim_set_asv_waypoints(waypoints)
#        task = Orocos::TaskContext.get 'asv_navigation'
#        if waypoints.size > 0 
#            waypoints.each do |x,y|
#                task.addWaypoint(x,y)
#            end
#        end
#    end
#
#    def self.sim_moving_asv
#        waypoints = []
#        waypoints << [5.0, 2.0] << [0.0,-2.4] << [-3.0,3.0]
#        sim_set_asv_waypoints(waypoints)
#    end
#
#    def self.sim_clear_asv_waypoints
#        task = Orocos::TaskContext.get 'asv_navigation'
#        task.clearWaypoints
#    end
#
        def sim_set_avalon(object)
            buoy = { :x => 43.58, :y => 0.56, :z => -2.21, :theta => 1.3 } #rad
            pipe = { :x => 31.6, :y => 1.52, :z => -2.2, :theta => -0.10 } # rad
            wall = { :x => 45.0, :y => 2.5, :z => -4.5, :theta => 0.0 }
            zero = { :x => 0, :y => 0, :z => 0, :theta => 0.0 }
            sauce_start = { :x => 31.0, :y => -8.0, :z => -2.5, :theta => Math::PI / 2.0 }

            position = nil

            case object
            when :buoy
                position = buoy
            when :pipeline
                position = pipe
            when :wall
                position = wall
            when :sauce_start
                position = sauce_start
            when :zero
                position = zero
            else
                position = pipe
            end

            sim_set_pose(position[:x], position[:y], position[:z], position[:theta])
        end
        command :sim_set_avalon, "set the position of avalon",
            :object => "valids are: :buoy,:pipe,:wall,:zero,:sauce_start"
    end
end
#module Robot
#    def self.avalon
#        @avalon_interface_internal ||= Avalon::ShellInterface.new(Roby.app)
#    end
#end

Roby::Interface::Interface.subcommand 'avalon', Avalon::ShellInterface, 'Commands specific to Avalon'
