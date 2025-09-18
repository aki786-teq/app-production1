class StretchDistancesController < ApplicationController
  before_action :authenticate_user!
  before_action :check_consecutive_posts, only: [ :measure, :analyze, :create_post_with_result ]
  before_action :set_stretch_distance, only: [ :result ]

  def measure
    @stretch_distance = StretchDistance.new
    @consecutive_days = current_user.consecutive_post_days
  end

  def analyze
    stretch_distance_params = params.require(:stretch_distance).permit(:flexibility_level)

    @stretch_distance = current_user.stretch_distances.build(stretch_distance_params)

    if @stretch_distance.save
      render json: {
        success: true,
        stretch_distance_id: @stretch_distance.id,
        flexibility_level: @stretch_distance.flexibility_level,
        comment: @stretch_distance.comment_template,
        result_url: result_stretch_distance_path(@stretch_distance)
      }
    else
      render json: {
        success: false,
        errors: @stretch_distance.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  def result
    @consecutive_days = current_user.consecutive_post_days
  end

  def create_post_with_result
    stretch_distance = current_user.stretch_distances.find(params[:id])

    session[:stretch_measurement_data] = {
      flexibility_level: stretch_distance.flexibility_level,
      comment: stretch_distance.comment_template,
      created_at: stretch_distance.created_at.strftime("%Y年%m月%d日 %H:%M")
    }

    redirect_to new_board_path(stretch_distance_id: stretch_distance.id)
  rescue ActiveRecord::RecordNotFound
    redirect_to measure_stretch_distances_path, alert: "測定記録が見つかりません。"
  end

  private

  def set_stretch_distance
    @stretch_distance = current_user.stretch_distances.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to measure_stretch_distances_path, alert: "測定記録が見つかりません。"
  end

  def check_consecutive_posts
    unless current_user.can_use_stretch_measurement?
      consecutive_days = current_user.consecutive_post_days
      remaining_days = 4 - consecutive_days

      redirect_to root_path,
                  alert: "前屈測定機能を利用するには昨日から過去4日間の連続投稿が必要です。現在#{consecutive_days}日連続投稿中です。あと#{remaining_days}日継続してください。"
    end
  end
end
