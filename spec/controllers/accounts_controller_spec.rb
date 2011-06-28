require 'spec_helper'

describe AccountsController do

  shared_examples_for "an action requiring a logged-in user" do

    it 'should require a logged-in user' do
      make_request
      flash[:notice].should == 'You must be logged in to access this page.'
    end

  end

  describe 'GET #show' do

    def make_request
      get :show
    end

    it_should_behave_like 'an action requiring a logged-in user'

  end

  describe 'GET #edit' do

    def make_request
      get :edit
    end

    it_should_behave_like 'an action requiring a logged-in user'

    describe 'when a user is logged in' do

      before do
        @mock_user = mock_model(User, :errors => mock('errors', :on => []),
                                      :name => '',
                                      :email => '',
                                      :password => '',
                                      :password_confirmation => '')
        controller.stub!(:current_user).and_return(@mock_user)
      end

      it 'should render the edit template' do
        make_request
        response.should render_template("edit")
      end

    end

  end

  describe 'PUT #update' do

    before do 
      @default_params = { :user => { :email => 'test@example.com' } }
    end
    
    def make_request(params=@default_params)
      put :update, params
    end

    it_should_behave_like 'an action requiring a logged-in user'

    describe 'when a user is logged in' do

      before do
        @mock_user = mock_model(User, :email= => true,
                                      :password= => true,
                                      :password_confirmation= => true,
                                      :save => true,
                                      :update_attributes => true)
        controller.stub!(:current_user).and_return(@mock_user)
      end

      it 'should update the current users account info' do
        @mock_user.should_receive(:email=).with('test@example.com')
        make_request(@default_params)
      end
      
      describe 'if the user enters a password' do 
        
        it 'should set the account as registered and set the confirmed password flag' do 
          @mock_user.should_receive(:registered=).with(true)
          @mock_user.should_receive(:confirmed_password=).with(true)
          make_request(@default_params.merge({:user => {:password => 'password'}}))
        end
        
      end

      describe 'if the update is successful' do

        it "should redirect to the user's profile page" do
          make_request(@default_params)
          response.should redirect_to(profile_path(@mock_user))
        end

      end

      describe 'if the update is not successful' do

        before do
          @mock_user.stub!(:save).and_return(false)
        end

        it 'should render the edit template' do
          make_request(@default_params)
          response.should render_template('edit')
        end

      end

    end

  end

  describe 'GET #new' do

    def make_request
      get :new
    end

    it 'should not require a logged-in user' do
      make_request
      flash[:notice].should be_nil
    end

    it 'should render the "new" template' do
      make_request
      response.should render_template('new')
    end

  end

  describe 'POST #create' do

    before do
      @mock_user = mock_model(User, :valid? => false,
                                    :name= => true,
                                    :email= => true,
                                    :password= => true,
                                    :password_confirmation= => true,
                                    :ignore_blank_passwords= => true,
                                    :registered= => true,
                                    :registered? => false)
      User.stub!(:find_or_initialize_by_email).and_return(@mock_user)
    end

    def make_request(format="html")
      post :create, { :user => { :name => 'A name',
                                 :email => 'new_user@example.com',
                                 :password => "A password",
                                 :password_confirmation => "A password confirmation" },
                      :format => format }
    end

    it 'should find or initialize a user object using the email address' do
      User.should_receive(:find_or_initialize_by_email).with("new_user@example.com")
      make_request
    end

    it 'should set attributes on the user object based on the form params' do
      @mock_user.should_receive(:name=).with("A name")
      @mock_user.should_receive(:password=).with("A password")
      @mock_user.should_receive(:password_confirmation=).with("A password confirmation")
      make_request
    end

    it 'should test the user object to see if it is valid' do
      @mock_user.should_receive(:valid?)
      make_request
    end

    describe 'if the user model is valid' do

      before do
        @mock_user.stub!(:valid?).and_return(true)
        @mock_user.stub!(:save_without_session_maintenance)
        @mock_user.stub!(:reset_perishable_token!)
        @controller.stub!(:save_post_login_action_to_database)
        UserMailer.stub!(:deliver_new_account_confirmation)
      end

      describe 'if this is a new email address' do

        before do
          @mock_user.stub!(:new_record?).and_return(true)
        end

        it 'should save the user (not logging them in)' do
          @mock_user.should_receive(:save_without_session_maintenance)
          make_request
        end

        it 'should ask the user mailer to send an account confirmation email' do
          UserMailer.should_receive(:deliver_new_account_confirmation)
          make_request
        end
        
        it 'should save the next action to the database' do 
          @controller.should_receive(:save_post_login_action_to_database)
          make_request
        end
        
        describe 'if there is no post login action set' do

          it 'should set the action message for the confirmation template to an account confirmation message' do
            make_request
            assigns[:action].should == "your account won't be created."
          end
        
        end
        
        describe 'if the post_login_action is to create a problem' do
          
          before do 
            @controller.stub!(:get_action_data).and_return({:action => :create_problem})
          end
          
          it 'should set the action for the confirmation template to a problem creation message' do 
            make_request
            assigns[:action].should == "your problem will not be created."
          end
           
        end
        
        describe 'if the request asks for html' do 
          
          it 'should render the "confirmation_sent" template' do
            make_request
            response.should render_template("shared/confirmation_sent")
          end
          
        end
        
        describe 'if the request asks for json' do 
        
          it 'should return the "confirmation_sent" template rendered as a string in the response' do 
            @controller.stub!(:render_to_string).with(:partial => 'shared/confirmation_sent').and_return("content")
            make_request(format="json")
            JSON.parse(response.body)['html'].should == "content"
          end
        end
        
      end
      
      describe 'if this is an email address that has an unregistered account' do 
      
        before do 
          @mock_user.stub!(:new_record?).and_return(false)
          @mock_user.stub!(:registered?).and_return(false)
          UserMailer.stub!(:deliver_account_exists)
        end
        
        it 'should ask the user mailer to send an "already exists" email' do 
          UserMailer.should_receive(:deliver_account_exists)
          make_request
        end
        
        it 'should render the "confirmation_sent" template' do 
          make_request
          response.should render_template("shared/confirmation_sent")
        end
        
      end

      describe 'if this is an email address that has a registered account' do

        before do
          @mock_user.stub!(:new_record?).and_return(false)
          @mock_user.stub!(:registered?).and_return(true)
          UserMailer.stub!(:deliver_already_registered)
        end

        it 'should ask the user mailer to send an "already registered" email' do
          UserMailer.should_receive(:deliver_already_registered)
          make_request
        end

        it 'should render the "confirmation_sent" template' do
          make_request
          response.should render_template("shared/confirmation_sent")
        end

      end

    end

    describe 'if the user model is not valid' do

      before do
        @mock_user.stub!(:valid?).and_return(false)
        @mock_user.stub!(:errors).and_return([[:base, "Test error message"]])
      end

      describe 'if the request asks for html' do 
        
        it 'should render the "new" template' do
          make_request
          response.should render_template('new')
        end
    
      end

      describe 'if the request asks for json' do
        
        it 'should return a json hash with a key for errors' do 
          make_request(format="json")
          JSON.parse(response.body)['errors'].should == {'base' => 'Test error message'}
        end
        
        it 'should return a json hash with a success key set to false' do 
          make_request(format="json")
          JSON.parse(response.body)['success'].should == false
        end
        
      end
    end

  end

  describe 'GET #confirm' do

    def make_request
      get :confirm, :email_token => 'my_token'
    end

    it 'should look for a user by perishable token' do
      User.should_receive(:find_using_perishable_token)
      make_request
    end

    describe 'if no user is found using the perishable token' do

      before do
        User.stub!(:find_using_perishable_token).with('my_token', 0).and_return(nil)
      end

      it 'should show an error message saying that the account cannot be found' do
        make_request
        flash[:error].should == "We're sorry, but we could not locate your account. If you are having issues try copying and pasting the URL from your email into your browser or restarting the reset password process."
      end

      it 'should redirect to the root url' do
        make_request
        response.should redirect_to(root_url)
      end

    end

    describe 'if a user can be found using the perishable token param' do

      before do
        UserSession.stub!(:login_by_confirmation)
        @mock_user = mock_model(User, :registered? => false,
                                      :registered= => true,
                                      :confirmed_password= => true,
                                      :crypted_password => "password",
                                      :post_login_action => nil,
                                      :save_without_session_maintenance => true,
                                      :post_login_action= => nil)
        User.stub!(:find_using_perishable_token).with('my_token', 0).and_return(@mock_user)
      end

      it 'should redirect to the saved location or the front of the application' do
        make_request
        response.should redirect_to(root_url)
      end
      
      describe 'if the user model has a post login action' do 
    
        
        describe 'if the action is joining a campaign' do 
    
          before do 
            @mock_user.stub!(:post_login_action).and_return('join_campaign')
            @mock_campaign = mock_model(Campaign)
            @mock_supporter = mock_model(CampaignSupporter, :confirm! => true,
                                                            :campaign => @mock_campaign)
            CampaignSupporter.stub!(:find_by_token).and_return(@mock_supporter)
          end
          
          it 'should look for the campaign supporter model by the confirmation token' do 
            CampaignSupporter.should_receive(:find_by_token).with("my_token")
            make_request
          end
          
          it 'should confirm the campaign support' do 
            @mock_supporter.should_receive(:confirm!)
            make_request
          end
          
          it 'should the redirect to the campaign path' do 
            make_request
            response.should redirect_to(campaign_url(@mock_campaign))
          end

        end
        
        describe 'if the action is creating a problem' do 
          
          before do 
            @mock_user.stub!(:post_login_action).and_return('create_problem')
            @mock_problem = mock_model(Problem)
            Problem.stub!(:find_by_token).and_return(@mock_problem)
          end
        
          it 'should look for the problem by the confirmation token' do 
            Problem.should_receive(:find_by_token).and_return(@mock_problem)
            make_request
          end
                    
          it 'should redirect to the problem conversion url' do 
            make_request
            response.should redirect_to(convert_problem_url(@mock_problem))
          end
          
        end
        
        describe 'if the action is adding a comment' do 
        
          before do 
            @mock_user.stub!(:post_login_action).and_return('add_comment')
            @mock_problem = mock_model(Problem)
            @mock_comment = mock_model(Comment, :confirm! => true, :commented => @mock_problem)
            Comment.stub!(:find_by_token).and_return(@mock_comment)
          end
          
          it 'should look for the comment by the confirmation token' do 
            Comment.should_receive(:find_by_token)
            make_request
          end
          
          it 'should confirm the comment' do 
            @mock_comment.should_receive(:confirm!)
            make_request
          end
          
          it 'should redirect to the url of the thing being commented on' do 
            make_request
            response.should redirect_to(problem_url(@mock_problem))
          end
          
        end
        
      end
      
      describe 'if the user has a crypted password' do
        
        it 'should show a notice that the user has confirmed their account' do
          make_request
          flash[:notice].should == 'You have successfully confirmed your account.'
        end

        it 'should set the user to registered' do
          @mock_user.should_receive(:registered=).with(true)
          make_request
        end
            
      end
      
      describe "if the user doesn't have a crypted password" do 
        
        before do 
          @mock_user.stub!(:crypted_password).and_return(nil)
        end
      
        it 'should show a notice saying that the user has logged in and should set a password' do 
          make_request
          flash[:notice].should == "You've successfully logged in. Set a password on your account to make it easier to come back."
        end
        
        it "should redirect to the user's account if there is no redirect defined by a post-login action" do 
          make_request
          response.should redirect_to(edit_account_url)
        end
        
      end

      it 'should log the user in' do
        UserSession.should_receive(:login_by_confirmation).with(@mock_user)
        make_request
      end
      
    end

  end

end