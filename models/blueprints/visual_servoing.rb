require "#{File.dirname(__FILE__)}/../../../rock/models/blueprints/control"

module Avalon
    data_service_type 'RelativePositionDetectorSrv' do
        provides RelativePositionCommandSrv
    end
end

