class Asset
  include Mongoid::Document
  include Mongoid::Timestamps
  include MongoBasicSearch::Searchable
  include Mongoid::Paperclip

  IMAGE_REGEX = /(jpg|jpeg|gif|png)/
  NORMALIZED_EXTENSIONS = { ".jpeg" => ".jpg" }


  field :file_content_type, type: String
  field :file_file_name, type: String
  field :file_file_size, type: Integer
  field :file_fingerprint, type: String
  field :file_dimensions, type: Hash, default: {}

  field :tags, type: String
  field :page_cache, type: Array, default: []

  basic_text_search_in :file_file_name, :tags, :search_page_cache

  has_mongoid_attached_file :file,
    default_style:   :admin,
    max_size:        50.megabytes,
    url:             '/system/:attachment/:mon_year/:id/:style/:filename',
    path:            ':rails_root/public:url',
    only_process:    [:admin],
    styles:          Slices::Config.asset_styles,
    convert_options: Slices::Config.asset_convert_options

  validates_attachment :file, presence: true
  do_not_validate_attachment_file_type :file

  before_file_post_process :is_image?
  after_file_post_process :store_dimensions, if: :is_image?
  before_save :reset_file_dimensions!, if: :file_fingerprint_changed?
  before_save :rename_file
  after_destroy :remove_asset_from_pages

  has_and_belongs_to_many :pages

  index({ file_fingerprint: 1 })
  index({ _keywords: 1 }, { background: true })

  def self.make(*args)
    Slices::Asset::Maker.run(*args)
  end

  def self.search_for(term = nil)
    if term.present?
      all.ordered_active.basic_text_search term
    else
      all.ordered_active
    end
  end

  def self.ordered_active
    desc(:created_at)
  end

  def as_json(options = nil)
    {
      id:                id.to_s,
      name:              name,
      file_file_name:    file_file_name,
      file_file_size:    file_file_size,
      file_content_type: file_content_type,
      asset_url:         admin_image_url,
      original_url:      file.url(:original),
      errors:            errors,
      created_at:        created_at,
      tags:              tags,
      pages:             page_cache.each { |pc| pc[:id] = pc[:id].to_s }
    }
  end

  # Returns the url for the asset style. The style is created if it has not already
  # been generated
  #
  # @param [Symbol] style     The asset style is defined in Slice::Config.asset_styles
  def url_for(style)
    reprocess_for(style)
    file.url(style)
  end

  # Returns the dimensions the asset style. The style is created if it has not already
  # been generated
  #
  #   asset.dimensions_for(:main)
  #   "100x100"
  #
  # @param [Symbol] style     The asset style is defined in Slice::Config.asset_styles
  def dimensions_for(style)
    reprocess_for(style)
    file_dimensions[style.to_s]
  end

  def reprocess_for(style)
    if file.styles.has_key?(style) && ! file_dimensions.has_key?(style.to_s)
      file.reprocess!(style)
    end
  rescue Errors::NotIdentifiedByImageMagickError, Errno::ENOENT
  end

  def reprocess_for!(style)
    file.clear(style)
    file_dimensions.delete(style.to_s)
    file.flush_deletes
    reprocess_for(style)
  end

  def store_dimensions
    file.queued_for_write.each do |style, adapter|
      geometry = Paperclip::Geometry.from_file(adapter)
      self.file_dimensions[style.to_s] = geometry.to_s
    end
  end

  def is_image?
    file_content_type.present? && file_content_type.match(IMAGE_REGEX).present?
  end

  def file_extension
    if file_file_name.present?
      file_file_name.split('.').last.downcase
    else
      ''
    end
  end

  def admin_image_url
    if !new_record? && is_image?
      url_for(:admin)
    end
  end

  def remove_asset_from_pages
    pages.each do |page|
      page.remove_asset(self)
      page.save if page.changed?
    end
  end

  def name
    @new_name || file_file_name
  end

  def name=(new_name)
    @new_name = new_name
  end

  def update_page_cache
    pages.exists?
    self.page_cache = pages.collect do |page|
      { id: page.id, name: page.name, path: page.path }
    end
  end

  def search_page_cache
    page_cache.inject([]) do |memo, page|
      memo << page['name']
      memo << page['path']
    end.join ' '
  end

  # Reset all stored file dimensions except for the origin and admin styles,
  # this is used when a new version of an asset is uploaded
  #
  def reset_file_dimensions!
    self.file_dimensions.keys.each do |key|
      next if key == 'original' || key == 'admin'
      self.file_dimensions.delete key
    end
  end

  private

  def rename_file
    return if @new_name.blank?

    new_file_name = sanitize(@new_name)
    Slices::Asset::Rename.run(file, new_file_name)
    file.instance_write(:file_name, new_file_name)
    set_keywords
    @new_name = nil
  end

  def sanitize(filename)
    SecureRandom.hex
  end

  def normalized_extension
    extname = File.extname(file.original_filename).downcase
    NORMALIZED_EXTENSIONS.fetch(extname, extname)
  end

end
