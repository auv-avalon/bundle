require 'scripts/controllers/main'
require 'models/profiles/avalon_simulation/main'
require 'scripts/controllers/auto_starter'

class Simulation::MarsIMU
    on :start do |event|
        @pose_reader = data_reader 'pose_samples'
    end
    poll do
        if rbs = @pose_reader.read
           State.pose.orientation = rbs.orientation
           if !State.pose.respond_to?(:position)
               State.pose.position = Eigen::Vector3.new(0, 0, 0)
           end
           State.pose.position = rbs.position
           State.pose.orientation= rbs.orientation
        end
    end
end


sim = Robot.sim_def!

State.start_time = Time.new
State.buoyancy = nil

Roby.every(1.0, :on_error => :disable) do
    if State.start_time + 7 < Time.new
        if !State.buoyancy
            STDOUT.puts "Starting buoyancy"
            State.buoyancy = Robot.buoyancy_def!
            Robot.sonar_def!
            Robot.bottom_cam_def!
            Robot.front_cam_def!
        end
    end
end

module Robot
    def set_state(state, substate)
        State.lowlevel_state = state
        State.lowlevel_substate = substate
    end
#    def self.sim_set_position(x, y, z)
#        task = Orocos::TaskContext.get 'avalon_simulation'
#        task.setPosition(x, y, z)
#    end
#
#    def self.sim_set_pose(x, y, z, yaw)
#        task = Orocos::TaskContext.get 'avalon_simulation'
#        task.setPosition(x, y, z)
#        task.setYaw(yaw)
#    end
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
#    def self.sim_set_avalon(object)
#        buoy = { :x => 43.58, :y => 0.56, :z => -2.21, :theta => 1.3 } #rad
#        pipe = { :x => 31.6, :y => 1.52, :z => -2.2, :theta => -0.10 } # rad
#        wall = { :x => 45.0, :y => 2.5, :z => -4.5, :theta => 0.0 }
#        sauce_start = { :x => 31.0, :y => -8.0, :z => -2.5, :theta => Math::PI / 2.0 }
#
#        position = nil
#
#        case object
#        when :buoy
#            position = buoy
#        when :pipeline
#            position = pipe
#        when :wall
#            position = wall
#        when :sauce_start
#            position = sauce_start
#        else
#            position = pipe
#        end
#
#        sim_set_pose(position[:x], position[:y], position[:z], position[:theta])
#    end
    
#    def self.emergency_surfacing
#        task = Orocos::TaskContext.get('actuators')
#	task.command.disconnect_all
#        writer = task.command.writer
#        sample = writer.new_sample
#        sample.time = Time.now
#        sample.mode = [:DM_PWM] * 6
#        sample.target = [0, -0.5, 0, 0, 0, 0]
#        Roby.each_cycle do |_|
#            writer.write(sample)
#        end
#    end
end

