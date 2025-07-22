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

    if current_user.goal.present?
      @board.goal = current_user.goal
      @board.goal_title     = current_user.goal.goal
      @board.goal_content   = current_user.goal.content
      @board.goal_reward    = current_user.goal.reward
      @board.goal_punishment = current_user.goal.punishment
    end

    if @board.save
      redirect_to boards_path, success: t('boards.flash_message.create_success')
    else
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

  def bookmarks
  @bookmarks = current_user.bookmarks.includes(:board).order(created_at: :desc)
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
            item_code: item['itemCode'],
            item_name: item['itemName'],
            item_price: item['itemPrice'],
            item_url: item['itemUrl'],
            small_image_urls: item['smallImageUrls'],
            medium_image_urls: item['mediumImageUrls']
          }
        end
      }
    rescue => e
      Rails.logger.error "楽天API検索エラー: #{e.message}"
      render json: { error: '商品検索でエラーが発生しました' }, status: :unprocessable_entity
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
end