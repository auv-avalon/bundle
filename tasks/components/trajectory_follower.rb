class TrajectoryFollower::Task
    provides Motion2DCommand

    def configure
        super

	orogen_task.controllerType = 0
	orogen_task.forwardVelocity = 0.50
        orogen_task.gpsCenterofRotationOffset = 0.0
	orogen_task.forwardLength = 0.15
	orogen_task.K0_nO = 5.0
	orogen_task.K2_P = 100
	orogen_task.K3_P = 50

	orogen_task.K0_PI = 0
	orogen_task.K2_PI = 100
	orogen_task.K3_PI = 50
    end  

    on :start do |event|
        if file = State.trajectory_file
            Robot.info "loading test trajectory from #{file}"

            result_t = Orocos.registry.get('/std/vector</wrappers/Waypoint>')
            result = result_t.wrap(File.read(file))

            if State.reverse_trajectory? && State.reverse_trajectory
                Robot.info "inverting the trajectory"
                inverted = result_t.new
                result.to_a.reverse.each do |p|
                    inverted.insert(p)
                end
                result = inverted
            end

            @writer = orogen_task.trajectory.writer :type => :buffer, :size => 1
            @writer.write(result)
        end
    end

    on :stop do |event|
        if @writer
            @writer.disconnect
        end
    end
end

Compositions::ControlLoop.specialize Command => TrajectoryFollower::Task do
    add Pose
    export self['command'].trajectory
    autoconnect
end

