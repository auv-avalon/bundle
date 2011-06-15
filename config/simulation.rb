Roby.app.use_deployments_from "avalon_simulation"
Roby.app.use_deployments_from "avalon_front"
Roby.app.use_deployments_from "avalon_back"
State.orocos.disable_logging

State.navigation_mode = ['pipeline']
Robot.devices do
    device(Dev::BottomCameraSimulation, :as => "bottom_camera").
        period(0.1)
end

Roby::State.update do |s|
end
