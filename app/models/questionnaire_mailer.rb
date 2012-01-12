class QuestionnaireMailer < ApplicationMailer

  include ActionView::Helpers::DateHelper
  cattr_accessor :dryrun
  
  def questionnaire(issue, questionnaire, user, title)
    recipients user
    from contact_from_name_and_email
    subject I18n.translate('mailers.questionnaire_subject', :title => title)
    body({ :recipient => user,
           :title => title,
           :description => issue.description,
           :link => main_url(questionnaire_path(:email_token => questionnaire.token)),
           :time_ago => time_ago_in_words(issue.confirmed_at) })
  end
  
  def self.send_questionnaires(dryrun=false)
    self.dryrun = dryrun
    weeks_ago = 4
    problems = Problem.needing_questionnaire(weeks_ago)
    campaigns = Campaign.needing_questionnaire(weeks_ago)
    (problems + campaigns).each do |issue|
      if issue.is_a?(Problem) 
        user = issue.reporter 
        title = issue.subject
      else
        user = issue.initiator
        title = issue.title
      end
      if !(user.suspended? || user.is_hidden?)
        questionnaire = issue.questionnaires.create!(:user => user, :sent_at => Time.now)
        if self.dryrun
          STDERR.puts("Would send the following:")
          mail = create_questionnaire(issue, questionnaire, user, title)
          STDERR.puts(mail)
        else
          self.deliver_questionnaire(issue, questionnaire, user, title)
        end
      end
      if !self.dryrun
        issue.send_questionnaire = false
        issue.save!
      end
    end
    
  end

end