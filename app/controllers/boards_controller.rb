class BoardsController < ApplicationController
  def index
    @boards = Board.includes(:user).order(created_at: :desc)
  end

  def new
    if current_user.boards.where(created_at: Time.zone.today.all_day).exists?
      redirect_to boards_path, danger: t('boards.flash_message.daily_limit')
    else
      @board = Board.new
    end
  end

  def create
    if current_user.boards.where(created_at: Time.zone.today.all_day).exists?
      flash[:alert] = t('boards.flash_message.daily_limit')
      redirect_to boards_path and return
    end

    @board = current_user.boards.build(board_params)

    # デバッグ用ログ追加
    Rails.logger.info "=== Board作成デバッグ ==="
    Rails.logger.info "Board attributes: #{@board.attributes.inspect}"
    Rails.logger.info "Board methods: #{@board.methods.grep(/goal/).sort}"
    Rails.logger.info "Current user goal: #{current_user.goal.inspect}"

    if current_user.goal.present?
      @board.goal = current_user.goal
      
      begin
        @board.goal_title = current_user.goal.goal
        @board.goal_content = current_user.goal.content
        @board.goal_reward = current_user.goal.reward
        @board.goal_punishment = current_user.goal.punishment
        Rails.logger.info "Goal fields設定完了"
      rescue => e
        Rails.logger.error "Goal fields設定エラー: #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
        raise e
      end
    end

    if @board.save
      redirect_to boards_path, success: t('boards.flash_message.create_success')
    else
      Rails.logger.error "Board保存エラー: #{@board.errors.full_messages}"
      flash.now[:danger] = t('boards.flash_message.create_failure')
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @board = Board.find(params[:id])
  end

  def edit
    @board = current_user.boards.find(params[:id])
  end

  def update
    @board = current_user.boards.find(params[:id])
    if @board.update(board_params)
      redirect_to boards_path, success: t('boards.flash_message.update_success')
    else
      flash.now[:danger] = t('boards.flash_message.update_failure')
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    board = current_user.boards.find(params[:id])
    board.destroy!
    redirect_to boards_path, success: t('boards.flash_message.destroy_success'), status: :see_other
  end

  private

  def board_params
    permitted = params.require(:board).permit(:did_stretch, :content, :flexibility_level, :goal_id, :image)
    permitted[:did_stretch] = ActiveModel::Type::Boolean.new.cast(permitted[:did_stretch])
    permitted
  end
end