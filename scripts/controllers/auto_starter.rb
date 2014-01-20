require 'models/profiles/main'


#State.soft_timeout = #something

current_mode = nil 
current_submode = nil
run_start = nil
last_navigation_task = nil


#Define the possible modes that can be set
State.navigation_mode = ["drive_simple_def","buoy_def", "pipeline_def", "wall_right_def"]

#Reading the Joystick task to react on changes if an statechage should be done...
Roby.every(0.1, :on_error => :disable) do
    next if !State.lowlevel_state?


    #Check wether we should stop an current operation mode
    if (State.lowlevel_state != 5 and  State.lowlevel_state != 3) or ((State.lowlevel_substate != current_submode) and current_submode)
        if current_mode
            Roby.plan.unmark_mission(current_mode.task)
            last_navigation_task = current_mode.task
            current_mode = nil
            current_submode = nil
        end
    end


    #Workaround for someting withing roby
    if last_navigation_task
        last_navigation_task = nil if !last_navigation_task.plan # WORKAROUND: we're waiting for the task to be GCed by Roby before injecting the next navigation mode

    #Check if we should start anything
    elsif State.lowlevel_state == 5 or State.lowlevel_state == 3
        #Make sure nothing is running so far to prevent double-starting
        if !current_mode
            #Check if the submode is a valid one
            if(State.navigation_mode[State.lowlevel_substate])
                Robot.info "starting navigation mode #{State.navigation_mode[State.lowlevel_substate]}, we are currently at #{current_mode}"
                current_submode = State.lowlevel_substate
                nm, _ = Robot.send("#{State.navigation_mode[State.lowlevel_substate]}!")
                pp nm
                current_mode = nm.as_service
            elsif
                Robot.info "Cannot Start unknown substate!!!!! -#{State.navigation_mode[State.lowlevel_substate]}-"
            end

            if(State.soft_timeout?)
                run_start = Time.now
            end
        end
    end

    if(State.soft_timeout? and run_start)
        if(Time.now - run_start > State.soft_timeout)
            begin
    	        Orocos::TaskContext.get('hbridge').stop
                rescue Exception => e
                    Robot.info "Error #{e} during the stop of hbridges occured"
            end
            Roby.engine.quit
        end
    end
end
