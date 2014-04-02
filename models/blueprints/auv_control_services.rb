import_types_from 'base'
import_types_from 'auv_control'

module AuvControl
    #WORLD_TO_ALIGNED
    data_service_type 'WorldXYZRollPitchYawSrv' do
        input_port 'world_cmd', 'base/LinearAngular6DCommand'
    end

    data_service_type 'WorldZRollPitchYawSrvVelocityXY' do
        input_port 'world_cmd', 'base/LinearAngular6DCommand'
        input_port 'Velocity_cmd', 'base/LinearAngular6DCommand'
    end
end
