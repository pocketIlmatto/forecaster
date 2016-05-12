require "tmpdir"
require "fileutils"

RSpec.describe Forecaster do
  before do
    Forecaster.configure do |config|
      config.cache_dir = Dir.mktmpdir
      config.records = {
        :tmp => ":TMP:2 m above ground:" # Temperature
      }
    end

    t = Time.now - 86400
    @y = t.year
    @m = t.month
    @d = t.day
    @c = 0 # hour of GFS run
    @h = 3 # hour of forecast
  end

  after do
    FileUtils.remove_entry_secure(Forecaster.configuration.cache_dir)
  end

  it "requires wgrib2" do
    wgrib2_path = Forecaster.configuration.wgrib2_path
    out = `#{wgrib2_path} -version`

    expect(out).to start_with("v0.2")
  end

  it "fetches a forecast" do
    forecast = Forecaster.fetch(@y, @m, @d, @c, @h)

    expect(forecast.fetched?).to be true
  end

  describe Forecaster::Forecast do
    it "fetches a forecast" do
      forecast = Forecaster::Forecast.new(@y, @m, @d, @c, @h)

      expect(forecast.fetched?).to be false
      forecast.fetch
      expect(forecast.fetched?).to be true
    end

    it "reads a forecast" do
      forecast = Forecaster::Forecast.new(@y, @m, @d, @c, @h)

      forecast.fetch
      value = forecast.read(:tmp, longitude: 48.1147, latitude: -1.6794)
      expect(value).to be_a(String)
      expect(value.to_i).to be_between(180, 340).inclusive # in Kelvin
    end
  end
end