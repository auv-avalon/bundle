# This is the robot controller. This file is required last, after Roby has been
# fully set up. If you have to initialize some services at startup, to it here

require 'controllers/common_controller'
Roby.app.apply_orocos_deployment 'avalon' #From config/deployments

navigation_mode = nil 
last_substate = 0 
#Orocos.log_all_ports :exclude_types => '/can/Message'#, :exclude_ports => 'can.hbridge_set'
#Orocos.log_all_ports :exclude_types => '/canbus/Message'#, :exclude_ports => 'can.hbridge_set'

#Roby.every(1, :on_error => :disable) do
#	task = Roby.plan.find_tasks(Orocos::RobyPlugin::Dynamixel::Task).running.find { true }
#	if(task)
#		writer = task.cmd_angle.writer
#		writer.write(1)
#	end
#end



Roby.every(0.1, :on_error => :disable) do
#    State.lowlevel_substate = 7
    if State.lowlevel_state?
        if State.lowlevel_state != 3 and State.lowlevel_state != 5
            if navigation_mode
	    	Robot.info "Stopping current mode because we are not autonomoues"
                Roby.plan.unmark_mission(navigation_mode.task)
		navigation_mode = nil
            end
        elsif State.lowlevel_state == 3 or State.lowlevel_state == 5
            if !State.navigation_mode?
                Robot.warn "switched to mode 3, but no navigation mode is selected in State.navigation_mode, means array in config/avalon.rb empty"
            elsif !navigation_mode or last_substate != State.lowlevel_substate
		if navigation_mode and last_substate != State.lowlevel_substate
			Robot.warn "Stopping current navigation mode becase we switched"
			Roby.plan.unmark_mission(navigation_mode.task)
			navigation_mode = nil
		end
	    	
		Robot.info "Starting mode number: #{State.lowlevel_substate}"
                if(State.navigation_mode[State.lowlevel_substate])
			Robot.info "starting navigation mode #{State.navigation_mode[State.lowlevel_substate]}, we are currently at #{navigation_mode}"
			navigation_mode, _ = Robot.send("#{State.navigation_mode[State.lowlevel_substate]}!")
	               	navigation_mode = navigation_mode.as_service
			last_substate = State.lowlevel_substate
		elsif
			Robot.info "Cannot Start unknown substate!!!!! -#{State.navigation_mode[State.lowlevel_substate]}-"
		end
            end
        end
    end
end

Roby.every(1, :on_error => :disable) do
#	a = State.lowlevel_substate
#	pp "Current State is: #{a}"
end

#    if State.milestone1_mode? && State.milestone1_mode == :from_the_pond
#        if !State.milestone1?
#            State.drive_mode = 'trajectories'
#            State.reverse_trajectory = false
#            if State.pose?
#                State.milestone1 = :part_1
#                Robot.info "Milestone1: went into part 1"
#            end
#        end
#
#        # Start point : 24, 48
#        if State.milestone1 == :part_1
#            # Look for our position
#            x, y, _ = State.pose.position.data.to_a
#            if x > 24
#                # Start mode switching
#                following = Roby.plan.find_tasks(Orocos::RobyPlugin::TrajectoryController::Task).
#                    to_a.first
#                if following
#                    Orocos.engine.remove(Orocos::DataServices::Driving)
#                    change_time = Time.now
#                    State.milestone1 = :part_1_end
#                    Robot.info "Milestone1: waiting for part 1 to end"
#                end
#            end
#        end
#
#        # End point: 28, 50
#        if State.milestone1 == :part_1_end
#            if Time.now - change_time > 5
#                Orocos.engine.add_mission('visual_servoing')
#                State.milestone1 = :part_2_init
#            end
#        end
#
#        if State.milestone1 == :part_2_init
#            # Look for a servoing task
#            servoing_task = Roby.plan.find_tasks(Orocos::RobyPlugin::VisualServoing::Task).
#                to_a.first
#            if servoing_task
#                servoing_task.on :stop do |event|
#                    Orocos.engine.remove(Orocos::DataServices::Driving)
#                    State.milestone1 = :part_2_end
#                    change_time = Time.now
#                    Robot.info "Milestone1: waiting for part 2 to end"
#                end
#
#                State.milestone1 = :part_2
#                Robot.info "Milestone1: in part 2"
#                change_time = Time.now
#            end
#        end
#
#        if State.milestone1 == :part_2
#            if Time.now - change_time > 90
#                servoing_task = Roby.plan.find_tasks(Orocos::RobyPlugin::VisualServoing::Task).
#                    to_a.first
#                if servoing_task.running? && !servoing_task.stop_event.pending?
#                    servoing_task.stop! 
#                end
#            end
#        end
#
#        if State.milestone1 == :part_2_end
#            if Time.now - change_time > 5
#                Orocos.engine.add_mission('trajectories')
#                State.milestone1 = :part_3
#                Robot.info "Milestone1: in part 3"
#            end
#        end
#    end
#
#    if State.milestone1_mode? && State.milestone1_mode == :from_the_bridge
#        if !State.milestone1?
#            State.reverse_trajectory = true
#            State.drive_mode = 'visual_servoing'
#            if State.pose?
#                State.milestone1 = :part_1_init
#                Robot.info "Milestone1: went into part 1"
#            end
#        end
#
#        if State.milestone1 == :part_1_init
#            # Look for a servoing task
#            servoing_task = Roby.plan.find_tasks(Orocos::RobyPlugin::VisualServoing::Task).
#                to_a.first
#            if servoing_task
#                servoing_task.on :stop do |event|
#                    Orocos.engine.remove(Orocos::DataServices::Driving)
#                    State.milestone1 = :part_1_end
#                    change_time = Time.now
#                    Robot.info "Milestone1: waiting for part 1 to end"
#                end
#
#                State.milestone1 = :part_1
#                Robot.info "Milestone1: in part 1"
#                change_time = Time.now
#            end
#        end
#
#        if State.milestone1 == :part_1_end
#            # Change back to trajectories only if we got a RTK_FIXED position
#            if State.pose? && State.pose.position.data[0] > 20 && Time.now - change_time > 5
#                Orocos.engine.add_mission('trajectories')
#                State.milestone1 = :part_2
#                Robot.info "Milestone1: in part 2"
#            end
#        end
#    end
#end
