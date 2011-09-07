class Admin::ProblemsController < Admin::AdminController

  def show 
    @problem = Problem.find(params[:id])
  end
  
  def index
    conditions = []
    query_clauses = []
    if params[:query]
      query = params[:query].downcase
      query_clause = "(lower(subject) like ?"
      conditions << "%%#{query}%%" 
      # numeric?
      if query.to_i.to_s == query
        query_clause += " OR id = ?"
        conditions << query.to_i
      end  
      query_clause += ")"
      query_clauses << query_clause
    end
    conditions = [query_clauses.join(" AND ")] + conditions
    @problems = Problem.paginate :page => params[:page], 
                                 :conditions => conditions, 
                                 :order => 'id desc'
  end
  
  def resend
    @problem = Problem.find(params[:id])
    sent_emails = ProblemMailer.send_report(@problem, 
                                            @problem.emailable_organizations, 
                                            @problem.unemailable_organizations)
    if @problem.campaign
      @problem.campaign.campaign_events.create!(:event_type => 'problem_report_resent', 
                                                :data => { :user => user_for_edits,
                                                           :sent_emails => sent_emails.map{ |sent_email| sent_email.id } })
    end
    flash[:notice] = t('admin.problem_resent')
    redirect_to :action => 'show'
  end
  
  def update
    @problem = Problem.find(params[:id])
    @problem.status_code = params[:problem][:status_code]
    if @problem.update_attributes(params[:problem])
      flash[:notice] = t('admin.problem_updated')
      redirect_to admin_url(admin_problem_path(@problem.id))
    else
      flash[:error] = t('admin.problem_problem')
      render :show
    end
  end
  
end
