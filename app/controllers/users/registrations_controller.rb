class Users::RegistrationsController < Devise::RegistrationsController
  prepend_before_action :authenticate_scope!, only: [ :edit, :update, :destroy ]
  before_action :configure_account_update_params, only: [ :update ]

  # 新規登録失敗のフラッシュメッセージ
  def create
    super do |resource|
      if resource.errors.any?
        flash[:danger] = I18n.t("devise.registrations.new.failure")
      end
    end
  end

  def update
    self.resource = resource_class.to_adapter.get!(send(:"current_#{resource_name}").to_key)
    prev_unconfirmed_email = resource.unconfirmed_email if resource.respond_to?(:unconfirmed_email)

    resource_updated = update_resource(resource, account_update_params)

    if resource_updated
      if update_needs_confirmation?(resource, prev_unconfirmed_email)
        flash[:success] = "確認メールを送信しました。メール内のリンクをクリックして変更を完了してください。"
      else
        flash[:success] = "アカウント情報を変更しました。"
      end
      bypass_sign_in resource, scope: resource_name
      redirect_to after_update_path_for(resource)
    else
      clean_up_passwords resource
      set_minimum_password_length
      respond_with resource
    end
  end

  def edit
    super
  end

  private

  # Deviseが内部で呼び出しているメソッドの上書き（新規登録後のリダイレクト先）
  def after_sign_up_path_for(resource)
    new_goal_path
  end

  def configure_account_update_params
    devise_parameter_sanitizer.permit(:account_update, keys: [ :email, :password, :password_confirmation, :current_password ])
  end

  def update_needs_confirmation?(resource, prev_unconfirmed_email)
    resource.respond_to?(:pending_reconfirmation?) &&
      resource.pending_reconfirmation? &&
      prev_unconfirmed_email != resource.unconfirmed_email
  end
end
