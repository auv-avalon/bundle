using_task_library "camera_prosilica"

device_type 'CameraProsilica' do
    provides Srv::ImageProvider
end

class CameraProsilica::Task
    provides Dev::CameraProsilica, 'images' => 'frame'

    def configure
    	super
        orogen_task.camera_id = robot_device.device_id
    end
end

