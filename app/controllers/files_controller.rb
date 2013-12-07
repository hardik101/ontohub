class FilesController < ApplicationController

  helper_method :repository, :ref, :oid, :path, :branch_name, :dirpath
  before_filter :check_permissions, only: [:new, :create]

  def files
    @info = repository.path_info(params[:path], oid)

    raise Repository::FileNotFoundError, path if @info.nil?

    if request.format == 'text/html' || @info[:type] != :file
      case @info[:type]
      when :file
        @file = repository.read_file(path, oid)
      when :file_base
        ontology = repository.ontologies.
                    where(basepath: File.basepath(@info[:entry][:path])).
                    order('id asc').first
        redirect_to [repository, ontology]
      end
    else
      send_download(path, oid)
    end
  end

  def download
    send_download(path, oid)
  end

  def entries_info
    render json: repository.entries_info(oid, path)
  end

  def diff
    @message = repository.commit_message(oid)
    @changed_files = repository.changed_files(oid)
  end

  def history
    @per_page = 25
    page = @page = params[:page].nil? ? 1 : params[:page].to_i
    offset = page > 0 ? (page - 1) * @per_page : 0

    @ontology = repository.primary_ontology(path)

    if repository.empty?
      @commits = []
    else
      @current_file = repository.read_file(path, oid) if path && !repository.dir?(path)
      @commits = repository.commits(start_oid: oid, path: path, offset: offset, limit: @per_page)
    end
  end

  def new
    build_file
  end

  def create
    if build_file.valid?
      repository.save_file @file.file.path, @file.filepath, @file.message, current_user
      flash[:success] = "Successfully saved uploaded file."
      redirect_to fancy_repository_path(repository, path: @file.path)
    else
      render :new
    end
  end

  protected

  def repository
    @repository ||= Repository.find_by_path!(params[:repository_id])
  end

  def ref
    params[:ref] || 'master'
  end

  def dirpath
    return '' if params[:path].nil?
    parts = params[:path].split('/')
    dir = []
    parts.each_with_index do |part, i|
      unless repository.is_below_file?(parts[0..i].join('/'))
        dir << part
      end
    end

    dir.join('/')
  end

  def build_file
    args = params[:upload_file].merge({repository: repository}) unless params[:upload_file].nil?
    @file ||= UploadFile.new(args)
  end

  def check_permissions
    authorize! :write, repository
  end

  def send_download(path, oid)
    render text: repository.read_file(path, oid)[:content],
           content_type: Mime::Type.lookup('application/force-download')
  end

  def commit_id
    @commit_id ||= repository.commit_id(params[:ref])
  end

  def oid
    @oid ||= commit_id[:oid]
  end

  def branch_name
    commit_id[:branch_name]
  end

  def path
    params[:path]
  end

end
