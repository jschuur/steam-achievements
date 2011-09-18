class Achievements
  attr_reader :error, :id

  def initialize(user, game)
    if @achievements = load_game_achievements(user, game)
      @unlocked = @achievements.find_all { |a| a.unlocked? }.sort {|a,b| -1 * (a.timestamp.to_i <=> b.timestamp.to_i) }

      # 4 week history of the number of achievements unlocked
      achievements_per_day = @unlocked.map(&:timestamp).compact.reduce(Hash.new(0)) { |hash, timestamp| hash[timestamp.strftime("%D")] += 1; hash }
      @sparkline_history = (Date.today-28 .. Date.today).map { |d| achievements_per_day[d.strftime("%D")] }

      if user.to_i.to_s == user
        @id = SteamId.new(user.to_i)
      else
        @id = SteamId.new(user)
      end
    end
  end

  def all
    @achievements || []
  end

  def unlocked
    @unlocked || []
  end

  def sparkline_history
    @sparkline_history || []
  end

  private  

  def load_game_achievements(user, game)
    if cached_achievements = $redis.get("achievements_#{user}_#{game}")
      Marshal.load(cached_achievements)
    else
      begin
        if user.to_i.to_s == user
          id = SteamId.new(user.to_i)
        else
          id = SteamId.new(user)
        end

        # Save any profile we did a lookup on for later
        User.find_or_create_by_steam_id64(id.steam_id64) do |u|
          u.steam_id64 = id.steam_id64
          u.steam_real_name = id.real_name
          u.steam_privacy_state = id.privacy_state
          u.steam_nickname = id.nickname
          u.steam_custom_url = id.custom_url
          u.steam_base_url = id.base_url
          u.steam_full_avatar_url = id.full_avatar_url
          u.steam_medium_avatar_url = id.medium_avatar_url
          u.steam_icon_url = id.icon_url
        end

        raise "This profile's data is not public." if id.privacy_state != 'public'

        stats = id.game_stats(game)

        $redis.set("achievements_#{user}_#{game}", Marshal.dump(stats.achievements))
        $redis.expire("achievements_#{user}_#{game}", APP_CONFIG['achievement_cache_time'])

      rescue Exception => e
        @error = e.message
        return false
      else
        return stats.achievements
      end
    end
  end
end