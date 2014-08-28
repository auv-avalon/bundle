# This file will only be used if you convert this bundle into a full-fledged
# Roby application. This is done by calling
#
#   roby init
#
# From within the bundle root.

# This file is called to do application-global configuration. For configuration
# specific to a robot, edit config/NAME.rb, where NAME is the robot name.
#
# Enable some of the standard plugins
# Roby.app.using 'fault_injection'
# Roby.app.using 'subsystems'
Roby.app.using 'syskit'


require 'roby/schedulers/temporal'
Roby.scheduler = Roby::Schedulers::Temporal.new


#########################################################
#Diable logging at all!!
#Syskit.conf.orocos.conf_log_enabled=false
#Syskit.conf.disable_logging
#Syskit.conf.disable_conf_logging

#########################################################

##Roby::Application.reject_ambiguous_processor_deployments = false
#
#Syskit.conf.exclude_from_log '/canbus/Message'
#
## Does not work in multihost
## Roby.app.orocos_start_all_deployments = true
#
#Syskit.conf.log_group "images" do
#    add "/RTT/extras/ReadOnlyPointer</base/samples/frame/Frame>"
#end
#
###TODO Check namings before use##########################
##Syskit.conf.log_group "debug_images" do
##    add "buoy_detector.h_image"
##    add "buoy_detector.s_image"
##    add "pipeline_follower.debug_frame"
##    add "asv_detector.debug_image"
##end
##
##Syskit.conf.log_group "raw_camera" do
##    add "front_camera.frame_raw"
##    # add "front_camera.frame"
##    add "bottom_camera.frame_raw"
##    #add "camera_unicap_left.frame"
##    #add "camera_unicap_right.frame"
##end
#
##Syskit.conf.disable_log_group "images"
##Syskit.conf.disable_log_group "debug_images"
##Syskit.conf.disable_log_group "raw_camera"
#
#

## Uncomment to enable automatic transformer configuration support
Syskit.conf.transformer_enabled = true

##############################
# Sets some configuration options
#
# If true, the engine aborts if an uncaught task or event exception is
# received. Defaults to false, as Roby has meaningful ways to handle those
#  Roby.app.abort_on_exception = false
#
# If true, the engine aborts if an exception is raised outside of the reach of
# the plan-based error management. Defaults to true, as there is no safe ways
# to handle those.
#  Roby.app.abort_on_application_exception = true

##############################
# Set the decision control object to be used during execution (can also be
# done per-robot)
#
# Roby.control = Roby::DecisionControl.new


##############################
# Set the scheduler object to be used during execution (can also be done
# per-robot by setting it in config/#{ROBOT}.rb)

