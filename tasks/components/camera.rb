##
# oroGen camera component
#
# Example configuration:
#
#   Robot.devices do
#       device(Camera).
#           configure do |c|
#               c.colorspace = 'bayer8'
#           end
#   end
#
# Where 'p', above, accepts any settings that has a property in the CameraTask
# task context.
class Camera::CameraTask
    def configure
        super
        orogen_task.camera_id = robot_device.device_id
    end

    driver_for 'camera', :provides => DServ::ImageSource
end
