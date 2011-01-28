using_task_library 'trajectory_follower'
class CorridorNavigation::ServoingTask
    on :start do |event|
       Robot.info "starting Corridor servoing"
       imu_sample = State.odometry.orientation

       if !State.odometry?
           puts("Corridor servoing : No inital heading!")
           raise("No odometry orientation available")
       end

       h_sample = imu_sample.to_euler(2,1,0).x()
       puts("Corridor servoing : Inital heading #{h_sample}")

       orogen_task.heading.write h_sample
    end

    def configure
        super
        orogen_task.obstacle_safety_distance = 0.2
    end
end

composition 'CorridorServoing' do
    add LaserRangeFinder
    add(Compositions::ControlLoop).use('command' => TrajectoryFollower::Task)
    add RelativePose, :as => 'pose'
    add CorridorNavigation::ServoingTask
    autoconnect
end

