require 'highline'
CONSOLE = HighLine.new
def color(string, *args)
    CONSOLE.color(string, *args)
end

def add_status(status, name, format, obj, field, *colors)
    if !field.respond_to?(:to_ary)
        field = [field]
    end

    value = field.inject(obj) do |value, field_name|
        if value.respond_to?(field_name)
            value.send(field_name)
        else break
        end
    end

    if value
        if block_given?
            value = yield(value)
        end

        if value
            if format
                if !value.respond_to?(:to_ary)
                    value = [value]
                end

                status << color("#{name}=#{format}" % value, *colors)
            else
                status << color(name, *colors)
            end
        end
    else
        status << "#{name}=-"
    end
end


Roby.every(1, :on_error => :disable) do
    status = []

    add_status(status, "syslevel", "%i", State, :lowlevel_state)
    add_status(status, "pos", "(x=%.2f y=%.2f z=%.2f)", State, [:pose, :position]) do |p|
        p.to_a
    end
    add_status(status, "heading", "(%.2f)", State, [:pose, :orientation]) do |q|
        q.yaw * 180.0 / Math::PI
    end

    Robot.info status.join(' ') if !status.empty?
end
