module Regentanz
  # :nodoc:
  # Code taken from http://blade.nagaokaut.ac.jp/cgi-bin/scat.rb/ruby/ruby-talk/264573
  module Astronomy
    include Math
    
    private
    # :doc:

    def sun_rise_set(mode, lat, lng, zenith = 90.8333)
      #step 1: first calculate the day of the year
      mode = mode.to_sym
      date = Date.today
      n=date.yday

      #step 2: convert the longitude to hour value and calculate an approximate time
      lng_hour=lng/15
      t = n+ ((6-lng_hour)/24) if mode==:sunrise
      t = n+ ((18-lng_hour)/24) if mode==:sunset

      #step 3: calculate the sun's mean anomaly
      m = (0.9856 * t) - 3.289

      #step 4: calculate the sun's true longitude
      l = (m+(1.1916 * sin(deg_to_rad(m))) + (0.020 * sin(deg_to_rad(2*m))) + 282.634) % 360

      #step 5a: calculate the sun's right ascension
      ra = rad_to_deg(atan(0.91764 * tan(deg_to_rad(l)))) % 360

      #step 5b: right ascension value needs to be in the same quadrant as L
      lquadrant  = (l/90).floor*90
      raquadrant = (ra/90).floor*90
      ra         = ra+(lquadrant-raquadrant)

      #step 5c: right ascension value needs to be converted into hours
      ra/=15

      #step 6: calculate the sun's declination
      sin_dec = 0.39782 * sin(deg_to_rad(l))
      cos_dec = cos(asin(sin_dec))
      #step 7a: calculate the sun's local hour angle
      cos_h = (cos(deg_to_rad(zenith)) - (sin_dec * sin(deg_to_rad(lat)))) / (cos_dec * cos(deg_to_rad(lat)))

      return nil if (not (-1..1).include? cos_h)

      #step 7b: finish calculating H and convert into hours
      h = (360 - rad_to_deg(acos(cos_h)))/15 if mode==:sunrise
      h = (rad_to_deg(acos(cos_h)))/15       if mode==:sunset

      #step 8: calculate local mean time
      t = h + ra - (0.06571 * t) - 6.622
      t %=24

      #step 9: convert to UTC
      return (date.to_datetime+(t - lng_hour)/24).to_time.getlocal
    end

    # Convenience helper
    def deg_to_rad(degrees)
      degrees*PI/180
    end

    # Convenience helper
    def rad_to_deg(radians)
      radians*180/PI
    end

  end
end