device_type 'CameraUnicap', :config_type => CameraUnicap::CameraTask.config_type_from_properties do
    provides Srv::ImageProvider
end

class CameraUnicap::CameraTask
    provides Dev::CameraUnicap, 'frame' => 'frame'
end

