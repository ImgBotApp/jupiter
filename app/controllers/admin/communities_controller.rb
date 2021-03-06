class Admin::CommunitiesController < Admin::AdminController

  include CommunitiesCollectionsTypeahead

  before_action :fetch_community, only: [:show, :edit, :update, :destroy]

  def index
    respond_to do |format|
      format.html do
        @communities = Community.sort(sort_column, sort_direction).page params[:page]
        @title = t('.header')
        render template: 'communities/index'
      end
      format.json do
        results = typeahead_results(params[:query])
        render json: { results: results }
      end
    end
  end

  def show
    respond_to do |format|
      format.js do
        # Used for the collapsable dropdown to show member collections
        @collections = @community.member_collections.sort(sort_column, sort_direction)
        render template: 'communities/show'
      end
      format.html do
        @collections = @community.member_collections.sort(sort_column, sort_direction).page params[:page]
        render template: 'communities/show'
      end
    end
  end

  def new
    @community = Community.new_locked_ldp_object
  end

  def create
    @community =
      Community.new_locked_ldp_object(permitted_attributes(Community)
                                       .merge(owner: current_user&.id))

    if params[:community][:logo].present?
      @community.logo.attach(params[:community][:logo])
    end

    @community.unlock_and_fetch_ldp_object do |unlocked_community|
      if unlocked_community.save
        redirect_to [:admin, @community], notice: t('.created')
      else
        render :new, status: :bad_request
      end
    end
  end

  def edit; end

  def update
    if params[:community][:logo].present?
      # Note: monkey patch to ActiveStorage removes any previous versions
      @community.logo.attach(params[:community][:logo])
    end

    @community.unlock_and_fetch_ldp_object do |unlocked_community|
      if unlocked_community.update(permitted_attributes(Community))
        redirect_to [:admin, @community], notice: t('.updated')
      else
        render :edit, status: :bad_request
      end
    end
  end

  def destroy
    @community.unlock_and_fetch_ldp_object do |unlocked_community|
      if unlocked_community.destroy
        flash[:notice] = t('.deleted')
      else
        flash[:alert] = unlocked_community.errors.full_messages.first
      end

      redirect_to admin_communities_path
    end
  end

  private

  def fetch_community
    @community = Community.find(params[:id])
  end

  # Override the regular non-admin paths set in CommunitiesCollectionsTypeahead
  def path_to_community(community)
    admin_community_path(community)
  end

  def path_to_collection(collection)
    admin_community_collection_path(collection.community, collection)
  end

end
