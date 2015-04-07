require 'scripts/controllers/main'
require 'models/profiles/avalon_simulation/main'
require 'scripts/controllers/auto_starter'
require 'roby/interface'
require 'roby/robot'

class Mars::IMU
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
            State.buoyancy = true 
            Robot.sonar_def!
            Robot.thrusters_def! #For buoyancy
#            Robot.bottom_cam_def!
#            Robot.front_cam_def!
            Robot.imu_def!
        end
    end
end



    
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

