require_dependency 'previews_controller'

module RedmineAddressPreview
  module PreviewsControllerPatch
    def self.included(base) # :nodoc:
      base.send(:include, InstanceMethods) # obj.method

      base.class_eval do
        before_filter :issue_recipients
      end
    end

    module InstanceMethods # obj.method
      def issue_recipients
        # チケット情報の取得
        issue = nil
        issue = @project.issues.find_by_id(params[:id]) unless params[:id].blank?
        if issue.nil? # 新規作成
          issue = Issue.new
          issue.project = @project
          if params[:issue] && params[:issue][:watcher_user_ids]
            # 作成画面でチェックを付けていたウォッチャも対象にする
            issue.watcher_user_ids = params[:issue][:watcher_user_ids]
          end
        end

        # 宛先ユーザ
        users = (issue.notified_users | issue.watcher_users)

        # 宛先情報
        addresses = "\n\n*#{I18n.t(:label_address_preview)}:*\n"
        addresses << users.collect{|u| "# #{u.name}"}.join("\n")

        params[:issue] = {} unless params.key?(:issue)
        if issue.new_record?
          # 新規作成
          params[:issue][:description] ||= ''
          params[:issue][:description] << addresses
        else
          # 編集、更新
          params[:issue][:notes] ||= ''
          params[:issue][:notes] << addresses
        end
      end
    end
  end
end

PreviewsController.send(:include, RedmineAddressPreview::PreviewsControllerPatch)
