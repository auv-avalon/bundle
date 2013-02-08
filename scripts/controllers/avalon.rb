# This is the robot controller. This file is required last, after Roby has been
# fully set up. If you have to initialize some services at startup, to it here

require 'scripts/controllers/common_controller'
Roby.app.apply_orocos_deployment 'avalon' # load config/deployments/avalon.rb


navigation_mode = nil 
#State.navigation_mode = 'drive_simple'
current_submode = nil
run_start = nil
last_navigation_task = nil

SOFT_TIMEOUT = 10 * 60


#Workaround Task for hbridges
#Roby.every(0.5, :on_error => :disable) do
#    begin
#        mc = Orocos::TaskContext.get('motion_control')
#        hb = Orocos::TaskContext.get('hbridge')
#        if((hb.state == :TIMEOUT || hb.state == :RUNTIME_ERROR) and mc.state == :RUNNING)
#            hb.cmd_motors.disconnect_all
#            hb.cmd_motors.connect_to mc.hbridge_commands
#            pp "Reconnect motion_control::Task to HBridge"
#        end
#    rescue Exception => e
#        pp "An error occure during reconnection of the hbridges: #{e}"
#    end
#end




Roby.every(0.1, :on_error => :disable) do
    if State.lowlevel_state?
        if (State.lowlevel_state != 5 and  State.lowlevel_state != 3) or ((State.lowlevel_substate != current_submode) and current_submode)
            if navigation_mode
                Roby.plan.unmark_mission(navigation_mode.task)
               
               #workaround!!! supervision beended tasks nicht
               #Orocos::TaskContext.get('motion_control').stop
               #ende workaround
		
               last_navigation_task = navigation_mode.task
               navigation_mode = nil
               current_submode = nil
            end
        end
        if last_navigation_task
            if !last_navigation_task.plan # WORKAROUND: we're waiting for the task to be GCed by Roby before injecting the next navigation mode
                last_navigation_task = nil
            end
        #elsif State.lowlevel_state == 5 or State.lowlevel_state == 3
        elsif (State.lowlevel_state == 3) and false
            if !State.navigation_mode?
                Robot.warn "switched to mode 3, but no navigation mode is selected in State.navigation_mode"
            elsif !navigation_mode
                if(State.navigation_mode[State.lowlevel_substate])
                    Robot.info "starting navigation mode #{State.navigation_mode[State.lowlevel_substate]}, we are currently at #{navigation_mode}"
                    current_submode = State.lowlevel_substate
                    nm, _ = Robot.send("#{State.navigation_mode[State.lowlevel_substate]}!")
                    pp nm
                    navigation_mode = nm.as_service
                elsif
                    Robot.info "Cannot Start unknown substate!!!!! -#{State.navigation_mode[State.lowlevel_substate]}-"
                end


		#Robot.info "starting #{State.navigation_mode}"
		#navigation_mode, _ = Robot.send("#{State.navigation_mode}!")
		#navigation_mode = navigation_mode.as_service
		#run_start = Time.now
	    #elsif Time.now - run_start > SOFT_TIMEOUT
	    #	Roby.engine.quit
	#	Orocos::TaskContext.get('hbridge').stop
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

