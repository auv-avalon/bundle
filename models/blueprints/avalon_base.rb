require "#{File.dirname(__FILE__)}/../../../rock/models/blueprints/control"
require "#{File.dirname(__FILE__)}/../../../rock/models/blueprints/pose"

module Avalon
    Base::ControlLoop.declare 'AUVMotion', '/base/AUVMotionCommand'
    Base::ControlLoop.declare 'AUVRelativeMotion', '/base/AUVPositionCommand'

    data_service_type 'ModemConnectionSrv' do
            input_port 'white_light', 'bool'
            input_port 'position', '/base/samples/RigidBodyState'
            output_port 'motion_command', '/base/AUVMotionCommand'
    end


    data_service_type "RelativePositionCommandSrv" do
        #TODO Add data types
    end



    data_service_type 'SoundSourceDirectionSrv' do
        output_port 'angle', '/base/Angle'
    end

    data_service_type 'StructuredLightPairSrv' do
        output_port 'images', ro_ptr('/base/samples/frame/FramePair')
    end

#    data_service_type 'LaserScanProviderSrv' do
#        output_port 'laserscan', '/base/samples/LaserScan'
#    end


    #data_service_type 'Position' do
    #    output_port 'position_samples', '/base/samples/RigidBodyState'
    #end

    #data_service_type 'Orientation' do
    #    output_port 'orientation_samples', '/base/samples/RigidBodyState'
    #end
end
