module RedmineTrackControl
  module IssuesControllerPatch
    def self.included(base)
      base.send(:include, InstanceMethods)

      base.class_eval do
        unloadable
        helper 'track_control'

        alias_method_chain :build_new_issue_from_params, :tracker_control
        alias_method_chain :update_issue_from_params, :tracker_control
      end
    end

    module InstanceMethods
      def valid_trackers_list(project)  #Added for check whether user having a valid tracker for the project
        if project.enabled_modules.where(:name => "tracker_permissions").count == 1
          project.trackers.select{|t| User.current.allowed_to?("create_tracker#{t.id}".to_sym, project, :global => true)}.collect {|t| [t.name, t.id]}
        else
          project.trackers.collect {|t| [t.name, t.id]}
        end
      end

      def build_new_issue_from_params_with_tracker_control
        build_new_issue_from_params_without_tracker_control
        return true if @issue.project.enabled_modules.where(:name => "tracker_permissions").count == 0
        return true if User.current.admin?
        if valid_trackers_list(@issue.project).empty?  
          render_error l(:error_no_tracker_in_project)
          return false
        end
      end

      def update_issue_from_params_with_tracker_control
        old_tracker_id = @issue.tracker.id
        update_issue_from_params_without_tracker_control
        return true if (@issue.project.enabled_modules.where(:name => "tracker_permissions").count == 0) or (params[:tracker_id].blank?) or (old_tracker_id == params[:tracker_id])
        return true if User.current.admin?
        if valid_trackers_list(@issue.project).empty?  
          render_error l(:error_no_tracker_in_project)
          return false
        end
      end
    end
  end
end
