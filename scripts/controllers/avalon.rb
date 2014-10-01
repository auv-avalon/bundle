# This is the robot controller. This file is required last, after Roby has been
# fully set up. If you have to initialize some services at startup, to it here


using_task_library "auv_helper"
using_task_library "orientation_estimator"

require 'scripts/controllers/main'
require 'models/profiles/avalon/main'
require 'scripts/controllers/auto_starter'
    

class AuvHelper::DepthAndOrientationFusion
    on :start do |event|
        @pose_reader = data_reader :pose_samples
    end
    poll do
        if @pose_reader 
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
end

class PoseEstimation::UWPoseEstimator
    on :start do |event|
        @pose_reader = data_reader :pose_samples
    end
    poll do
        if @pose_reader 
            if rbs = @pose_reader.read
               #State.pose.orientation = rbs.orientation
               if !State.pose.respond_to?(:position)
                   State.pose.position = Eigen::Vector3.new(0, 0, 0)
               end
            end
        end
    end
end

#class OrientationEstimator::BaseEstimator
#    on :start do |event|
#        @pose_reader = data_reader :attitude_b_g
#    end
#    poll do
#        if @pose_reader 
 #           if rbs = @pose_reader.read
#                if(State.pos.position)
#                    State.pose.position[2] = rbs.position[2]
#                end
#               State.pose.orientation= rbs.orientation
#            end
#        end
#    end
#end

Robot.battery_dev!
Robot.sysmon_dev!
#Robot.modem_dev!
#Robot.depth_reader_dev!
#Robot.depth_reader_rear_dev!
Robot.depth_fusion_def!
#Robot.lights_def!
Robot.low_level_def!

#Robot.actuatorss_sensors_dev!
Robot.front_camera_dev!
Robot.bottom_camera_dev!
Robot.sonar_dev!
Robot.gps_dev!
Robot.blueview_dev!

#Robot.buoy_detector_def!
#Robot.pipeline_detector_def!
#Robot.localization_detector_def!


#bl = Robot.base_loop_def!
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
