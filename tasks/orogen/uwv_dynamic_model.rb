class AvalonModelParameter
end

class UwvDynamicModel::Task
    def configure
        # We need to set the model parameters before calling the
        # configure hook because they are used in there.
        puts "UwvDynamicModel: Initializing vehicle parameters ..."
        task = Orocos::TaskContext.get self.orocos_name

        # Get parameter property
        parameters = task.uwv_param

        # Set parameters
        AvalonModelParameters::intialise_vehicle_parameters(parameters)

        # Update parameter property
        task.uwv_param = parameters
    end
end


class AvalonModelParameters
    # UWV dimensional parameters
    def self.vehicle_dimensional_parameters(task)
        # vector position from the origin of body-fixed frame to center of buoyancy in body-fixed frame
        task.distance_body2centerofbuoyancy[0] = 0;
        task.distance_body2centerofbuoyancy[1] = 0;
        task.distance_body2centerofbuoyancy[2] = 0;

        # vector position from the origin of body-fixed frame to center of gravity in body-fixed frame
        task.distance_body2centerofgravity[0] = 0;
        task.distance_body2centerofgravity[1] = 0;
        task.distance_body2centerofgravity[2] = 0;
    end

    # UWV physical parameters
    def self.vehicle_physical_parameters(task)
        task.uwv_mass = 68 		# total mass of the vehicle in kg
        task.uwv_volume = ((0.445+0.56)*0.13*0.13*Math::PI+0.41*Math::PI*0.18*0.18)#(2*(0.55*0.15*0.15*Math::PI)+0.30*Math::PI*0.15*0.15) # total volume of the vehicle - considered as two cylinders and center as cylinder
        task.uwv_float = true		# to assume that the vehicle floats . i.e gravity == buoyancy
    end

    # Environment parameters
    def self.environmental_parameters(task)
        task.waterDensity = 998.2	# density of pure water at 20°C in kg/m^3
        task.gravity = 9.81
    end

    # UWV interia + added mass Matrix
    # consider Avalon as one big cylinder
    def self.mass_matrix(task)
        task.mass_matrix = [7.48,0,0,0,0,0,  0,16.29,0,0,0,0,  0,0,16.29,0,0,0,  0,0,0,0.61,0,0,  0,0,0,0,1.67,0,  0,0,0,0,0,1.67]
    end

    # Linear damp coefficient
    def self.linDampCoeff(task)
        task.linDampCoeff = [1.2832, 10, 10, 0, 1.7, 1.7 ]
    end

    # Quadratic damp coefficient
    def self.quadDampCoeff(task)
        task.quadDampCoeff = [8.962, 20, 20, 10, 50, 50]
    end
    # ThrusterCoefficient
    def self.thrusterCoefficient(task)
        task.thruster_coefficient.surge.positive = 0.005#-0.000045#-0.0000045
	task.thruster_coefficient.surge.negative = 0.005#-0.000045#-0.0000045
	task.thruster_coefficient.sway.positive = 0.005#000045
	task.thruster_coefficient.sway.negative = 0.005#000045
	task.thruster_coefficient.heave.positive = 0.005#000045
	task.thruster_coefficient.heave.negative = 0.005#000045
	task.thruster_coefficient.roll.positive = 0.0
	task.thruster_coefficient.roll.negative = 0.0
	task.thruster_coefficient.pitch.positive = 0.0#000045
	task.thruster_coefficient.pitch.negative = 0.0#000045
	task.thruster_coefficient.yaw.positive = 0.0#000045
	task.thruster_coefficient.yaw.negative = 0.0#000045
    end

    # Thruster mapping
    def self.thruster_mapping(task)
        array_thruster_value = task.thruster_value.to_a
            array_thruster_value= [25.4 , 25.4, 25.4, 25.4 , 25.4, 25.4]
        task.thruster_value = array_thruster_value

        array_thruster_mapped_names = task.thruster_mapped_names.to_a
            #array_thruster_mapped_names= "SURGE,SURGE,SWAY,SWAY,HEAVE,HEAVE".split(/,/)
            array_thruster_mapped_names= ['HEAVE','HEAVE','SURGE','SURGE','SWAY','SWAY']
        task.thruster_mapped_names = array_thruster_mapped_names

    end

    # Thruster control matrix
    def self.thruster_control_matrix(task)
        task.thruster_control_matrix = [0,0,1,0,-0.92,0,  0,0,1,0,0.205,0,  1,0,0,0,0,-0.17,  1,0,0,0,0,0.17,  0,1,0,0,0,-0.81,  0,1,0,0,0,0.04]
    end

    # Simulation parameters
    def self.simulation_data(task)
        task.sim_per_cycle = 5					# number of RK4 simulations per sampling interval
        task.plant_order = 12					# plant order - number of states in the model - generally 12 states -> 3 position, 3 orientation and 6 linear&angular velocity
        task.ctrl_order = 5;					# ctrl order - number of controllable inputs
        task.samplingtime = 0.1;           				# sampling time used in simulation
        task.initial_condition = [ 0,0,0,0,0,0, 0,0,0,0,0,0];	# Initial conditions used for simulation - currently it 12 states
        task.initial_time = 0.0;              			# Initial time	used for simulation
    end

    def self.intialise_vehicle_parameters(task)
        vehicle_dimensional_parameters(task)
        vehicle_physical_parameters(task)
        mass_matrix(task)
        linDampCoeff(task)
        quadDampCoeff(task)
        thrusterCoefficient(task)
        thruster_mapping(task.thrusters)
        thruster_control_matrix(task)
        simulation_data(task)
        task.thrusterVoltage = 25.4

    end
end

