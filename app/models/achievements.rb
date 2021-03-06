class Achievements
  attr_reader :error, :id
  include SteamUtil

  def initialize(id, game)
    if @achievements = load_game_achievements(id, game)
      @unlocked = @achievements.find_all { |a| a.unlocked? }.sort {|a,b| -1 * (a.timestamp.to_i <=> b.timestamp.to_i) }

      # 4 week history of the number of achievements unlocked
      achievements_per_day = @unlocked.map(&:timestamp).compact.reduce(Hash.new(0)) { |hash, timestamp| hash[timestamp.strftime("%D")] += 1; hash }
      @sparkline_history = (Date.today-28 .. Date.today).map { |d| achievements_per_day[d.strftime("%D")] }
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

  def load_game_achievements(id, game)
    if cached_achievements = $redis.get("achievements_#{id.steam_id64}_#{game}")
      Marshal.load(cached_achievements)
    else
      begin
        # Save any profile we did a lookup on for later
        User.create_with_id(id)

        raise "This profile's data is not public." if id.privacy_state != 'public'

        stats = id.game_stats(game)
      rescue Exception => e
        @error = e.message
        return false
      else
        $redis.set("achievements_#{id.steam_id64}_#{game}", Marshal.dump(stats.achievements))
        $redis.expire("achievements_#{id.steam_id64}_#{game}", APP_CONFIG['achievement_cache_time'] || 600)

        stats.achievements
      end
    end
  end
end