using_task_library "camera_prosilica"

device_type 'CameraProsilica', :config_type => CameraProsilica::Task.config_type_from_properties do
    provides Srv::ImageProvider
end

class CameraProsilica::Task
    provides Dev::CameraProsilica, 'images' => 'frame'

    def configure
    	super
        orogen_task.camera_id = robot_device.device_id
    end
end

