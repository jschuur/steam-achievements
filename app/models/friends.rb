class Friends
  def initialize(user)
    if user.to_i.to_s == user
      id = SteamId.new(user.to_i)
    else
      id = SteamId.new(user)
    end
    
    load_friends(id)
  end

  def all
    @friends || []
  end

  private
  
  def load_friends(id)
    if friends = id.friends
      WebApi.api_key = STEAM_WEB_API_KEY
      friends_json = WebApi.json 'ISteamUser', 'GetPlayerSummaries', 2, { :steamids => friends.map(&:steam_id64).join(',') }
      @friends = MultiJson.decode(friends_json)['response']['players']
    
      @friends.each_with_index do |friend, i|
        if friend['profileurl'] && friend['profileurl'].index('/id/')
          @friends[i]['custom_url'] = friend['profileurl'].split('/').last
        end
      end
    end
  end
end