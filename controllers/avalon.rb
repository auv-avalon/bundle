# This is the robot controller. This file is required last, after Roby has been
# fully set up. If you have to initialize some services at startup, to it here

require 'controllers/common_controller'
Roby.app.apply_orocos_deployment 'avalon' #From config/deployments

navigation_mode = nil 

Orocos.log_all_ports :exclude_types => '/can/Message'

#Roby.every(1, :on_error => :disable) do
#	task = Roby.plan.find_tasks(Orocos::RobyPlugin::Dynamixel::Task).running.find { true }
#	if(task)
#		writer = task.cmd_angle.writer
#		writer.write(1)
#	end
#end



Roby.every(0.1, :on_error => :disable) do
    if State.lowlevel_state?
        if State.lowlevel_state != 3
            if navigation_mode
                navigation_mode.stop!
                navigation_mode = nil
            end
        elsif State.lowlevel_state == 3
            if !State.navigation_mode?
                Robot.warn "switched to mode 3, but no navigation mode is selected in State.navigation_mode"
            elsif !navigation_mode
                Robot.info "starting navigation mode #{State.navigation_mode}"
                navigation_mode, _ = Robot.send("#{State.navigation_mode}!")
                navigation_mode = navigation_mode.as_service
            end
        end
    end
end

Roby.every(1, :on_error => :disable) do
	#pp "Current State is:"
	#a = State.lowlevel_state
	#pp a 
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
