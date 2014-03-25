
class RawControlCommandConverter::Movement

    on :start do |event|
        @raw_reader = data_reader :motion_command
    end

    poll do
        if !@raw_reader.nil?
            if sample = @raw_reader.read
                ::State.target_depth = sample.z
            end
        end
    end
end
