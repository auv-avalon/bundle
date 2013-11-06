# This is the robot controller. This file is required last, after Roby has been
# fully set up. If you have to initialize some services at startup, to it here


require 'scripts/controllers/main'
require 'models/profiles/avalon/main'
require 'models/profiles/avalon/auto_starter'
    

class AvalonControl::DephFusionCmp
    on :start do |event|
        @pose_reader = task_child.pose_samples_port.reader
    end
    poll do
        if rbs = @pose_reader.read
           State.pose.orientation = rbs.orientation
           if !State.pose.respond_to?(:position)
               State.pose.position = Eigen::Vector3.new(0, 0, 0)
           end
           State.pose.position[2] = rbs.position[2]
           State.pose.orientation= rbs.orientation
        end
    end
end

bl = Robot.base_loop_def!
#buoy = Robot.buoyancy_def!

#module Robot
#    def self.emergency_surfacing
#        task = Orocos::TaskContext.get('hbridge')
#	task.cmd_motors.disconnect_all
#        writer = task.cmd_motors.writer
#        sample = writer.new_sample
#        sample.time = Time.now
#        sample.mode = [:DM_PWM] * 6
#        sample.target = [0, -0.5, 0, 0, 0, 0]
#        Roby.each_cycle do |_|
#            writer.write(sample)
#        end
#    end
#end
#
