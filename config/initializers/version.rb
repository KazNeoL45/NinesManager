module NinesManager
  class Application
    VERSION = "0.8.0 | Ayane Rev"
    BETA = true
    BETA_NUMBER = 1
    CODENAME = "Chaos"
    STATUS = BETA ? "beta" : "live"

    def self.version
      VERSION
    end

    def self.beta?
      BETA
    end

    def self.beta_number
      BETA_NUMBER
    end

    def self.codename
      CODENAME
    end

    def self.status
      STATUS
    end

    def self.status_display
      BETA ? "Beta #{BETA_NUMBER} · #{CODENAME}" : "Live · #{CODENAME}"
    end
  end
end
