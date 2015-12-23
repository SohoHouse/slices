class Admin::AssetsController < Admin::AdminController
  layout 'admin'
  respond_to :json, :html

  def index
    respond_to do |format|
      format.html {}
      format.json do
        params[:per_page] = 50 unless params.include?(:per_page)
        @assets = Asset.search_for(params[:search]).paginate(params)
        render json: @assets.as_json
      end
    end
  end

  def create
    @asset = Asset.make asset_params

    respond_with do |format|
      format.json { render json: @asset }
    end
  end

  def update
    @asset = Asset.find(params[:id])
    @asset.update_attributes asset_params

    respond_with @asset do |format|
      format.json { render json: @asset }
    end
  end

  def destroy
    asset = Asset.find(params[:id])
    asset.destroy
    respond_to do |format|
      format.html { redirect_to admin_assets_path }
      format.json { render json: true }
    end
  end

  private

  def asset_params
    asset_params = params.permit([{asset: [:name, :tags]}, :file])
    if asset_params.key?(:file)
      file = asset_params[:file]
      file = URI(file.gsub(' ', '+')) if file.is_a?(String)
      { file: file }
    else
      asset_params[:asset]
    end
  end
end
