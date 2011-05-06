class ObjectServoing::Task

    def configure
        super
    refPos = orogen_task.reference_position
    refPos.x = 1.5
    refPos.y = 0
    refPos.z = 0
    orogen_task.reference_position = refPos
    dof = orogen_task.degree_of_freedom
    dof.x = true
    dof.y = false
    dof.z = false
    dof.heading = true
    orogen_task.degree_of_freedom = dof
    end
end

