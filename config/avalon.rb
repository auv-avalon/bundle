Roby.app.use_deployments_from "avalon_front"
Roby.app.use_deployments_from "avalon_back"

Robot.devices do
    device(Camera, :as => 'front_camera').
        period(0.03)

    device(AvalonLowLevel, :as => 'lowlevel').
        period(0.008)
    device(IfgFOG, :as => 'fog').
        period(0.1)
    device(DfkiImu, :as => 'imu').
        period(0.01)
end

