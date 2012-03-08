module ApplicationHelper
  def is_current_controller(cntlr_name)
    params[:controller] == cntlr_name ?  ' class="active"' : ''
  end
end
