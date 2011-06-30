# This is the robot controller. This file is required last, after Roby has been
# fully set up. If you have to initialize some services at startup, to it here

require 'controllers/common_controller'
Roby.app.apply_orocos_deployment 'avalon' # load config/deployments/avalon.rb

navigation_mode = nil 

# Roby.every(0.1, :on_error => :disable) do
# #    State.lowlevel_substate = 7
#     if State.lowlevel_state?
#         if State.lowlevel_state != 3 and State.lowlevel_state != 5
#             if navigation_mode
#                 Roby.plan.unmark_mission(navigation_mode.task)
# 		navigation_mode = nil
#             end
#         elsif State.lowlevel_state == 3 or State.lowlevel_state == 5
#             if !State.navigation_mode?
#                 Robot.warn "switched to mode 3, but no navigation mode is selected in State.navigation_mode"
#             elsif !navigation_mode
# 	    	Robot.info "Starting mode number: #{State.lowlevel_substate}"
#                 if(State.navigation_mode[State.lowlevel_substate])
# 			Robot.info "starting navigation mode #{State.navigation_mode[State.lowlevel_substate]}, we are currently at #{navigation_mode}"
# 			navigation_mode, _ = Robot.send("#{State.navigation_mode[State.lowlevel_substate]}!")
# 	               	navigation_mode = navigation_mode.as_service
# 		elsif
# 			Robot.info "Cannot Start unknown substate!!!!! -#{State.navigation_mode[State.lowlevel_substate]}-"
# 		end
#             end
#         end
#     end
# end

Roby.every(1, :on_error => :disable) do
	#pp "Current State is:"
	#a = State.lowlevel_state
	#pp a 
end
