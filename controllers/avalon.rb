# This is the robot controller. This file is required last, after Roby has been
# fully set up. If you have to initialize some services at startup, to it here

require 'controllers/common_controller'
Roby.app.apply_orocos_deployment 'avalon' # load config/deployments/avalon.rb

navigation_mode = nil 
State.navigation_mode = 'drive_simple'

run_start = nil
SOFT_TIMEOUT = 10 * 60
Roby.every(0.1, :on_error => :disable) do
    if State.lowlevel_state?
        if State.lowlevel_state != 5
            if navigation_mode
                Roby.plan.unmark_mission(navigation_mode.task)
		navigation_mode = nil
            end
        elsif State.lowlevel_state == 5
            if !State.navigation_mode?
                Robot.warn "switched to mode 3, but no navigation mode is selected in State.navigation_mode"
            elsif !navigation_mode
		Robot.info "starting #{State.navigation_mode}"
		navigation_mode, _ = Robot.send("#{State.navigation_mode}!")
		navigation_mode = navigation_mode.as_service
		run_start = Time.now
	    elsif Time.now - run_start > SOFT_TIMEOUT
	    	Roby.engine.quit
		Orocos::TaskContext.get('hbridge').stop
            end
        end
    end
end

module Robot
    def self.emergency_surfacing
        task = Orocos::TaskContext.get('hbridge')
	task.cmd_motors.disconnect_all
        writer = task.cmd_motors.writer
        sample = writer.new_sample
        sample.time = Time.now
        sample.mode = [:DM_PWM] * 6
        sample.target = [0, -0.5, 0, 0, 0, 0]
        Roby.each_cycle do |_|
            writer.write(sample)
        end
    end
end

