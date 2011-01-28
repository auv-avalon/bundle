class CameraFirewire::CameraTask
    driver_for 'CameraFirewire'

    on :start do |event|
        each_output_connection('frame') do |*value|
            puts "CONN: #{value.inspect}"
        end
    end

end

