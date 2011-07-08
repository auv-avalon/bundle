class MainPlanner
    method(:qualif_buoy) do
        find_and_strafe_buoy(:speed => 0,
                             :heading => nil,
                             :timeout => SIMPLE_FIND_BUOY_TIMEOUT,
                             :z => BUOY_Z)

    end

    method(:qualif_wall) do
        main = SaucE::QualifWall.new
        part1 = station_keep(:z => BUOY_Z)
        part2 = wall_servoing(:wall_left)
        main.add_sequence(part1, part2)
        main
    end
end
