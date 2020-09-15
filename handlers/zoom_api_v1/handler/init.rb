# Require the dependencies file to load the vendor libraries
require File.expand_path(File.join(File.dirname(__FILE__), "dependencies"))

class ZoomApiV1
  # ==== Parameters
  # * +input+ - The String of Xml that was built by evaluating the node.xml handler template.
  def initialize(input)
    # Set the input document attribute
    @input_document = REXML::Document.new(input)

    # Retrieve all of the handler info values and store them in a hash variable named @info_values.
    @info_values = {}
    REXML::XPath.each(@input_document, "/handler/infos/info") do |item|
      @info_values[item.attributes["name"]] = item.text.to_s.strip
    end

    # Retrieve all of the handler parameters and store them in a hash variable named @parameters.
    @parameters = {}
    REXML::XPath.each(@input_document, "/handler/parameters/parameter") do |item|
      @parameters[item.attributes["name"]] = item.text.to_s.strip
    end

    @debug_logging_enabled = ["yes","true"].include?(@info_values['enable_debug_logging'].downcase)
    @error_handling = @parameters["error_handling"]

    @api_location = "https://api.zoom.us/v2"
    @api_key = @info_values["api_key"]
    @api_secret = @info_values["api_secret"]

    @body = @parameters["body"].nil? ? "" : @parameters["body"]
    @method = (@parameters["method"] || :get).downcase.to_sym
    @path = @parameters["path"]
    @path = "/#{@path}" if !@path.start_with?("/")

    @accept = :json
    @content_type = :json
  end

  def execute
    # Initialize return data
    error_message = nil
    error_key = nil
    response_code = nil
    max_retries = 5
    retries = 0

    begin
      api_route = "#{@api_location}#{@path}"
      puts "API ROUTE: #{@method.to_s.upcase} #{api_route}" if @debug_logging_enabled
      puts "BODY: \n #{@body}" if @debug_logging_enabled

      token = getAssertion()

      response = RestClient::Request.execute \
        method: @method, \
        url: api_route, \
        payload: @body, \
        headers: {
          :content_type => @content_type, 
          :accept => @accept,
          :Authorization => "Bearer #{token}",
          :user_agent =>  "Zoom-Jwt-Request"
        }
      response_code = response.code
    rescue RestClient::Exception => e
      error = nil
      response_code = e.response.code

      # Attempt to parse the JSON error message.
      begin
        error = JSON.parse(e.response)
        error_message = error["error"]
        error_key = error["errorKey"] || ""
      rescue Exception
        puts "There was an error parsing the JSON error response" if @debug_logging_enabled
        error_message = e.inspect
      end

      # Retry the handler if attempting to update a stale object
      if (!error.nil? && @method.to_s.upcase == "PUT" && response_code == 400 &&
            error_key == "stale_record" && retries < max_retries)
        puts "Retrying update due to Stale Object Exception. Retry #{retries.to_s}: #{api_route}" if @debug_logging_enabled
        # Increment Retry Count
        retries += 1
        # Reset Error Message and Response Code
        error_message = nil
        error_key = nil
        retry
      end

      # Raise the error if instructed to, otherwise will fall through to
      # return an error message.
      raise if @error_handling == "Raise Error"
    end

    # Return (and escape) the results that were defined in the node.xml
    <<-RESULTS
    <results>
      <result name="Response Body">#{escape(response.nil? ? {} : response.body)}</result>
      <result name="Response Code">#{escape(response_code)}</result>
      <result name="Handler Error Message">#{escape(error_message)}</result>
    </results>
    RESULTS
  end

  ##############################################################################
  # General handler utility functions
  ##############################################################################

  def getAssertion()
    puts "in assertion" if @debug_logging_enabled

    now = Time.now.to_i
    plusHour = now + 3600

    payload = {
        "iss": @api_key,
        "exp": plusHour
      }

    return JWT.encode payload, @api_secret, 'HS256', header_fields={"typ":"JWT"}
  end

  # This is a template method that is used to escape results values (returned in
  # execute) that would cause the XML to be invalid.  This method is not
  # necessary if values do not contain character that have special meaning in
  # XML (&, ", <, and >), however it is a good practice to use it for all return
  # variable results in case the value could include one of those characters in
  # the future.  This method can be copied and reused between handlers.
  def escape(string)
    # Globally replace characters based on the ESCAPE_CHARACTERS constant
    string.to_s.gsub(/[&"><]/) { |special| ESCAPE_CHARACTERS[special] } if string
  end
  # This is a ruby constant that is used by the escape method
  ESCAPE_CHARACTERS = {'&'=>'&amp;', '>'=>'&gt;', '<'=>'&lt;', '"' => '&quot;'}
end
