require "models/blueprints/devices"
using_task_library "camera_prosilica"


class CameraProsilica::Task
    driver_for Dev::Sensors::Cameras::Network, :as => 'driver'
end

