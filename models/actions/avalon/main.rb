require "models/profiles/avalon"

class Main < Roby::Actions::Interface
    use_profile Avalon::Profiles::Avalon
end
