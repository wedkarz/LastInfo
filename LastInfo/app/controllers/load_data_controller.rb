class LoadDataController < ApplicationController
  # GET /load_data
  # GET /load_data.json
  def index
    
    #Settings
    api_key = '2d8dc0a751b42a8e4f6ca5aeb5c0c867'
    limit = 5

    countries = ["poland", "spain", "malta", "slovakia", "san+marino", "united+kingdom"]

    countries.each do |country|

      url = "http://ws.audioscrobbler.com/2.0/?method=geo.gettoptracks&country=#{country}&limit=#{limit}&api_key=#{api_key}"

      # get the XML data as a string
      xml_data = Net::HTTP.get_response(URI.parse(url)).body

      # extract event information
      #
      doc = REXML::Document.new(xml_data)

      doc.elements.each('lfm/toptracks/track') do |ele|

        songs << { "country" => #{country}, "songs" =>
          { "rank" => ele.attribute('rank'),
            "name" => ele.name,
            "duration" => ele.duration,
            "listeners" => ele.listeners,
            "artist" => ele.artist.name
          }
        }

        print songs
      end
    end
  end

  # GET /load_data/1
  # GET /load_data/1.json
  def show
    @load_datum = LoadDatum.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render :json => @load_datum }
    end
  end

  # GET /load_data/new
  # GET /load_data/new.json
  def new
    @load_datum = LoadDatum.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render :json => @load_datum }
    end
  end

  # GET /load_data/1/edit
  def edit
    @load_datum = LoadDatum.find(params[:id])
  end

  # POST /load_data
  # POST /load_data.json
  def create
    @load_datum = LoadDatum.new(params[:load_datum])

    respond_to do |format|
      if @load_datum.save
        format.html { redirect_to @load_datum, :notice => 'Load datum was successfully created.' }
        format.json { render :json => @load_datum, :status => :created, :location => @load_datum }
      else
        format.html { render :action => "new" }
        format.json { render :json => @load_datum.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /load_data/1
  # PUT /load_data/1.json
  def update
    @load_datum = LoadDatum.find(params[:id])

    respond_to do |format|
      if @load_datum.update_attributes(params[:load_datum])
        format.html { redirect_to @load_datum, :notice => 'Load datum was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render :action => "edit" }
        format.json { render :json => @load_datum.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /load_data/1
  # DELETE /load_data/1.json
  def destroy
    @load_datum = LoadDatum.find(params[:id])
    @load_datum.destroy

    respond_to do |format|
      format.html { redirect_to load_data_url }
      format.json { head :no_content }
    end
  end
end
