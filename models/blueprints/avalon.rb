require "rock/models/blueprints/control"
require "rock/models/blueprints/pose"

module Avalon
    Base::ControlLoop.declare 'AUVMotion', '/base/AUVMotionCommand'
    Base::ControlLoop.declare 'AUVRelativeMotion', '/base/AUVPositionCommand'
    Base::ControlLoop.declare "WorldXYZRollPitchYaw", 'base/LinearAngular6DCommand'
    data_service_type 'ModemConnectionSrv' do
            input_port 'white_light', 'bool'
            input_port 'position', '/base/samples/RigidBodyState'
            output_port 'motion_command', '/base/AUVMotionCommand'
    end

    data_service_type 'SoundSourceDirectionSrv' do
        output_port 'angle', '/base/Angle'
    end

    data_service_type 'StructuredLightPairSrv' do
        output_port 'images', ro_ptr('/base/samples/frame/FramePair')
    end

#    data_service_type 'SystemStatus' do
#        output_port 'system_status', 'sysmon/SystemStatus' 
#    end
#    
#    data_service_type 'ExperimentMarker' do
#        output_port 'annotations', 'logger/Annotations' 
#        output_port 'marker', 'sysmon/Marker' 
#    end

end


