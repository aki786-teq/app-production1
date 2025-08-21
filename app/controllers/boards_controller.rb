class BoardsController < ApplicationController
  before_action :authenticate_user!, except: [ :index, :show ]

  def index
    @pagy, @boards = pagy(Board.includes(:user).order(created_at: :desc))
  end

  def new
    if current_user.boards.where(created_at: Time.zone.today.all_day).exists?
      redirect_to boards_path, danger: t("boards.flash_message.daily_limit")
    else
      @board = Board.new

      # 前屈測定結果がセッションにある場合は本文に自動入力
      if session[:stretch_measurement_data].present?
        @stretch_data = session[:stretch_measurement_data]
        @board.content = format_stretch_measurement_content(@stretch_data)

        # セッションから削除（一度使用したら削除）
        session.delete(:stretch_measurement_data)
      end
    end
  end

  def create
    if current_user.boards.where(created_at: Time.zone.today.all_day).exists?
      flash[:alert] = t("boards.flash_message.daily_limit")
      redirect_to boards_path and return
    end

    @board = current_user.boards.build(board_params)

    if current_user.goal.present?
      @board.goal = current_user.goal
      @board.goal_title     = current_user.goal.goal
      @board.goal_content   = current_user.goal.content
      @board.goal_reward    = current_user.goal.reward
      @board.goal_punishment = current_user.goal.punishment
    end

    # 前屈測定結果IDがパラメータにある場合は関連付け
    if params[:stretch_distance_id].present?
      stretch_distance = current_user.stretch_distances.find_by(id: params[:stretch_distance_id])
      @board.stretch_distances << stretch_distance if stretch_distance
    end

    if @board.save
      # LINE通知の無投稿日数をリセット
      if current_user.line_notification_setting.present?
        current_user.line_notification_setting.reset_inactive_days!
      end

      redirect_to boards_path, success: t("boards.flash_message.create_success")
    else
      flash.now[:danger] = t("boards.flash_message.create_failure")
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
      redirect_to boards_path, success: t("boards.flash_message.update_success")
    else
      flash.now[:danger] = t("boards.flash_message.update_failure")
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
  board = current_user.boards.find(params[:id])
  board.destroy!
  redirect_to boards_path, success: t("boards.flash_message.destroy_success"), status: :see_other
  end

  def bookmarks
  @pagy, @bookmarks = pagy(current_user.bookmarks.includes(:board).order(created_at: :desc))
  end

  def search_items
    if params[:keyword].blank?
      render json: { items: [] }
      return
    end

    begin
      @items = RakutenWebService::Ichiba::Item.search(
        keyword: params[:keyword],
        hits: 5
      )

      render json: {
        items: @items.map do |item|
          {
            item_code: item["itemCode"],
            item_name: item["itemName"],
            item_price: item["itemPrice"],
            # アフィリエイトURLが返る場合は優先利用
            item_url: item["affiliateUrl"].presence || item["itemUrl"],
            small_image_urls: item["smallImageUrls"],
            medium_image_urls: item["mediumImageUrls"]
          }
        end
      }
    rescue => e
      Rails.logger.error "楽天API検索エラー: #{e.message}"
      render json: { error: "商品検索でエラーが発生しました" }, status: :unprocessable_entity
    end
  end

  private

  def board_params
    permitted = params.require(:board).permit(
      :did_stretch,
      :content,
      :flexibility_level,
      :goal_id,
      :image,
      :youtube_link,
      :item_code,
      :item_name,
      :item_price,
      :item_url,
      :item_image_url
    )
    permitted[:did_stretch] = ActiveModel::Type::Boolean.new.cast(permitted[:did_stretch])
    permitted
  end

  # 前屈測定結果を投稿本文用の文章に変換
  def format_stretch_measurement_content(stretch_data)
    flexibility_level_text = case stretch_data["flexibility_level"]
    when "excellent"
      "優秀"
    when "good"
      "良好"
    when "average"
      "普通"
    when "needs_improvement"
      "要改善"
    else
      stretch_data["flexibility_level"]
    end

    <<~TEXT
      🎉 前屈測定結果 🎉
      測定日時: #{stretch_data['created_at']}
      柔軟性レベル: #{flexibility_level_text}
      #{stretch_data['comment']}
    TEXT
  end
end
