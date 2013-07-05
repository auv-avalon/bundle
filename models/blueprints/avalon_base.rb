require "#{File.dirname(__FILE__)}/../../../rock/models/blueprints/control"
require "#{File.dirname(__FILE__)}/../../../rock/models/blueprints/pose"

module Avalon
    Base::ControlLoop.declare 'AUVMotion', '/base/AUVMotionCommand'
    Base::ControlLoop.declare 'AUVRelativeMotion', '/base/AUVPositionCommand'



    data_service_type 'ZProviderSrv' do
            output_port 'z_samples', '/base/samples/RigidBodyState'
    end


    data_service_type 'ModemConnectionSrv' do
            input_port 'white_light', 'bool'
            input_port 'position', '/base/samples/RigidBodyState'
            output_port 'motion_command', '/base/AUVMotionCommand'
    end


    data_service_type "RelativePositionCommandSrv" do
        #TODO Add data types
    end

    data_service_type 'OrientationWithZSrv' do
        output_port 'orientation_z_samples', '/base/samples/RigidBodyState'
        provides Base::OrientationSrv, 'orientation_samples' => 'orientation_z_samples'
        provides ZProviderSrv, 'z_samples' => 'orientation_z_samples'
    end

    #Prodived ground distance
    data_service_type 'GroundDistanceSrv' do
        output_port 'distance', '/base/samples/RigidBodyState'
    end

    data_service_type 'SonarScanProviderSrv' do
        output_port 'sonarscan', '/base/samples/SonarBeam'
    end

    data_service_type 'SoundSourceDirectionSrv' do
        output_port 'angle', '/base/Angle'
    end

    data_service_type 'StructuredLightPairSrv' do
        output_port 'images', ro_ptr('/base/samples/frame/FramePair')
    end

    data_service_type 'LaserScanProviderSrv' do
        output_port 'laserscan', '/base/samples/LaserScan'
    end

    data_service_type 'SpeedSrv' do
        output_port 'speed_samples', '/base/samples/RigidBodyState'
    end

    #data_service_type 'Position' do
    #    output_port 'position_samples', '/base/samples/RigidBodyState'
    #end

    #data_service_type 'Orientation' do
    #    output_port 'orientation_samples', '/base/samples/RigidBodyState'
    #end
end
