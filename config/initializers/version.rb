module NinesManager
  class Application
    VERSION = "0.7.0 | Ayane Rev"
    BETA = true
    STATUS = BETA ? "beta" : "live"

    def self.version
      VERSION
    end

    def self.beta?
      BETA
    end

    def self.status
      STATUS
    end
  end
end
