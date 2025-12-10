module ApplicationHelper
  def system_status_badge
    status = SystemStatus.new
    render 'shared/status_beta_view', status.to_h
  end

  def system_status
    SystemStatus.new.status
  end

  def system_healthy?
    SystemStatus.new.healthy?
  end
end
