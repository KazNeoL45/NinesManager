class SystemStatus
  def status
    if maintenance_mode?
      'maintenance'
    elsif NinesManager::Application.beta?
      'beta'
    else
      'live'
    end
  end

  def version
    NinesManager::Application.version
  end

  def healthy?
    !maintenance_mode?
  end

  def container_class
    if maintenance_mode?
      'bg-yellow-50 border-yellow-500 hover:bg-yellow-100'
    elsif NinesManager::Application.beta?
      'bg-blue-50 border-blue-500 hover:bg-blue-100'
    else
      'bg-green-50 border-green-500 hover:bg-green-100'
    end
  end

  def dot_class
    if maintenance_mode?
      'bg-yellow-500 animate-pulse'
    elsif NinesManager::Application.beta?
      'bg-blue-500 animate-pulse'
    else
      'bg-green-500'
    end
  end

  def text_class
    if maintenance_mode?
      'text-yellow-700'
    elsif NinesManager::Application.beta?
      'text-blue-700'
    else
      'text-green-700'
    end
  end

  def to_h
    {
      user_status: status,
      container_class: container_class,
      dot_class: dot_class,
      text_class: text_class
    }
  end

  private

  def maintenance_mode?
    File.exist?(Rails.root.join('tmp', 'maintenance.txt'))
  end
end
