Roby.app.use_deployments_from "avalon_simulation"
Roby.app.use_deployments_from "avalon_front"
Roby.app.use_deployments_from "avalon_back"
State.orocos.disable_logging

State.navigation_mode = ['pipeline']
Robot.devices do
    device(Dev::BottomCameraSimulation, :as => "bottom_camera").
        period(0.1)

    hbridge = device(Dev::HbridgeSetSimulation, :as => "hbridge").
        period(0.01).
        device_id("bla")

    hbridge.slave(Dev::HbridgesSimulation, :as => 'motors').
        select_ids(6,1,2,3,4,5)
    hbridge.configure

    #    configure do |task|
    #    	config = task.config
    #	config.numberOfBins 300
    #	config.adInterval 30
    #	config.initialGain 50
    #	task.config = config
    #    end
    #  
    # device(Dev::Camera, :as => "front_camera").
    #   period(0.1).
    #   device_id("53093").
    #   configure do |task|
    #   end
    #
end

Roby::State.update do |s|
end
