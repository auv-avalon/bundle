Roby.app.use_deployments_from "avalon_front"

Robot.devices do
    device(Camera, :as => 'front_camera').
        period(0.03)
    device(IGC, :as => 'imu').
        period(0.1)
end

