#!/bin/bash
# weather.sh - 10-day + today hourly for Otisville, MI
# Fixed-width columns for consistent alignment

LAT=43.1661
LON=-83.5244
CACHE="/tmp/conky-weather.json"
UPDATE_INTERVAL=1800

if [ ! -f "$CACHE" ] || [ $(($(date +%s) - $(stat -c %Y "$CACHE" 2>/dev/null || echo 0))) -gt $UPDATE_INTERVAL ]; then
  curl -s --max-time 15 \
    "https://api.open-meteo.com/v1/forecast?latitude=${LAT}&longitude=${LON}&daily=weather_code,temperature_2m_max,temperature_2m_min,precipitation_probability_max&hourly=temperature_2m,weather_code,precipitation_probability&current=temperature_2m,weather_code,relative_humidity_2m,wind_speed_10m&temperature_unit=fahrenheit&wind_speed_unit=mph&timezone=America%2FDetroit&forecast_days=10" \
    -o "$CACHE"
fi

if [ ! -s "$CACHE" ] || ! jq -e . "$CACHE" >/dev/null 2>&1; then
  echo '${color5}Weather data unavailable'
  exit 0
fi

code_to_desc() {
  case $1 in
    0) echo "Clear" ;;
    1) echo "Mainly clear" ;;
    2) echo "Partly cloudy" ;;
    3) echo "Overcast" ;;
    45|48) echo "Fog" ;;
    51|53|55) echo "Drizzle" ;;
    56|57) echo "Frz drizzle" ;;
    61) echo "Light rain" ;;
    63) echo "Mod rain" ;;
    65) echo "Heavy rain" ;;
    66|67) echo "Frz rain" ;;
    71) echo "Light snow" ;;
    73) echo "Mod snow" ;;
    75) echo "Heavy snow" ;;
    77) echo "Snow grains" ;;
    80) echo "Lt showers" ;;
    81) echo "Mod showers" ;;
    82) echo "Hvy showers" ;;
    85|86) echo "Snow showers" ;;
    95) echo "Thunderstorm" ;;
    96|99) echo "T-storm hail" ;;
    *) echo "Unknown" ;;
  esac
}

# Current
#CUR_TEMP=$(jq -r '.current.temperature_2m // empty' "$CACHE" | awk '{printf "%.0f",$1}')
#CUR_CODE=$(jq -r '.current.weather_code // empty' "$CACHE")
#CUR_HUM=$(jq -r '.current.relative_humidity_2m // empty' "$CACHE" | awk '{printf "%.0f",$1}')
#CUR_WIND=$(jq -r '.current.wind_speed_10m // empty' "$CACHE" | awk '{printf "%.0f",$1}')
#CUR_DESC=$(code_to_desc "$CUR_CODE")

#echo '${color6}${alignc}Current${color0}'
#echo "${color1}Temp:${color0} ${CUR_TEMP}°F  ${CUR_DESC}"
#echo "${color1}Humidity:${color0} ${CUR_HUM}%  ${color1}Wind:${color0} ${CUR_WIND} mph"
#echo '${color7}${hr 1}'

# Today hourly (every 3 hours)
echo '${color6}${alignc}Today Hourly'
TODAY=$(date +%Y-%m-%d)
NOW=$(date +%H)

jq -r --arg today "$TODAY" --argjson now "$NOW" '
  .hourly.time as $times |
  .hourly.temperature_2m as $temps |
  .hourly.weather_code as $codes |
  .hourly.precipitation_probability as $pops |
  [range(0; $times|length)] |
  map(select(
    ($times[.] | startswith($today)) and
    (($times[.] | split("T")[1] | split(":")[0] | tonumber) >= $now)
  )) |
  .[:16] | .[] |
  . as $i |
  ($times[$i] | split("T")[1] | split(":")[0] | tonumber) as $h |
  (if $h == 0 then "12AM" elif $h < 12 then ($h|tostring)+"AM" elif $h == 12 then "12PM" else (($h-12)|tostring)+"PM" end) as $hr |
  (if $codes[$i]==0 then "Clear"
   elif $codes[$i]==1 then "Mainly clear"
   elif $codes[$i]==2 then "Partly cloudy"
   elif $codes[$i]==3 then "Overcast"
   elif $codes[$i]==45 or $codes[$i]==48 then "Fog"
   elif $codes[$i]>=51 and $codes[$i]<=55 then "Drizzle"
   elif $codes[$i]==61 then "Light rain"
   elif $codes[$i]==63 then "Mod rain"
   elif $codes[$i]==65 then "Heavy rain"
   elif $codes[$i]==71 then "Light snow"
   elif $codes[$i]==73 then "Mod snow"
   elif $codes[$i]==75 then "Heavy snow"
   elif $codes[$i]>=80 and $codes[$i]<=82 then "Showers"
   elif $codes[$i]>=95 then "Thunderstorm"
   else "Unknown" end) as $desc |
  "\($hr)|\($temps[$i]|round)|\($desc)|\($pops[$i]|round)"
' "$CACHE" 2>/dev/null | while IFS='|' read -r hr temp desc pop; do
  printf '${color1}%-5s %4s° %-14s %4s%%${color0}\n' "$hr" "$temp" "$desc" "$pop"
done

echo '${color7}${hr 1}'

# 10-day
echo '${color6}${alignc}10-Day'
jq -r '
  .daily.time as $dates |
  .daily.temperature_2m_max as $highs |
  .daily.temperature_2m_min as $lows |
  .daily.weather_code as $codes |
  .daily.precipitation_probability_max as $pops |
  range(0; ($dates|length)) |
  . as $i |
  ($dates[$i] | strptime("%Y-%m-%d") | strftime("%a")) as $day |
  ($highs[$i]|round) as $hi |
  ($lows[$i]|round) as $lo |
  (if $codes[$i]==0 then "Clear"
   elif $codes[$i]==1 then "Mainly clear"
   elif $codes[$i]==2 then "Partly cloudy"
   elif $codes[$i]==3 then "Overcast"
   elif $codes[$i]==45 or $codes[$i]==48 then "Fog"
   elif $codes[$i]>=51 and $codes[$i]<=55 then "Drizzle"
   elif $codes[$i]==61 then "Light rain"
   elif $codes[$i]==63 then "Mod rain"
   elif $codes[$i]==65 then "Heavy rain"
   elif $codes[$i]==71 then "Light snow"
   elif $codes[$i]==73 then "Mod snow"
   elif $codes[$i]==75 then "Heavy snow"
   elif $codes[$i]>=80 and $codes[$i]<=82 then "Showers"
   elif $codes[$i]>=95 then "Thunderstorm"
   else "Unknown" end) as $desc |
  "\($day)|\($hi)|\($lo)|\($desc)|\($pops[$i]|round)"
' "$CACHE" 2>/dev/null | while IFS='|' read -r day hi lo desc pop; do
  printf '${color1}%-4s %3s°/%3s° %-14s %4s%%${color0}\n' "$day" "$hi" "$lo" "$desc" "$pop"
done
