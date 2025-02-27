/**
 * Manages game time, day/night cycle, and time-based events.
 * Follows Single Responsibility Principle by focusing on time management.
 */
class TimeManager {
  // Time state
  private float timeOfDay;
  private float initialTimeOfDay;
  private float timeScale;
  
  TimeManager() {
    timeOfDay = 0;
    initialTimeOfDay = random(1);  // Random start time
    timeScale = GameConfig.Time.DEFAULT_TIME_SCALE;  // Time progression speed
  }
  
  /**
   * Updates the time of day.
   */
  void update() {
    timeOfDay = (timeOfDay + timeScale) % GameConfig.Time.DAY_LENGTH;
  }
  
  /**
   * Gets the current adjusted time of day.
   */
  float getAdjustedTime() {
    return (timeOfDay + initialTimeOfDay) % GameConfig.Time.DAY_LENGTH;
  }
  
  /**
   * Gets a formatted string representation of the current time.
   */
  String getTimeString(float adjustedTime) {
    int hours = floor(adjustedTime * 24);
    int minutes = floor((adjustedTime * 24 - hours) * 60);
    return nf(hours, 2) + ":" + nf(minutes, 2);
  }
  
  /**
   * Gets the current time period.
   */
  TimePeriod getCurrentPeriod() {
    float adjustedTime = getAdjustedTime();
    
    if (adjustedTime < GameConfig.Time.DAY_START) return TimePeriod.DAWN;
    if (adjustedTime < GameConfig.Time.DUSK_START) return TimePeriod.DAY;
    if (adjustedTime < GameConfig.Time.NIGHT_START) return TimePeriod.DUSK;
    return TimePeriod.NIGHT;
  }
  
  /**
   * Checks if it's currently night time.
   */
  boolean isNightTime() {
    float adjustedTime = getAdjustedTime();
    return adjustedTime < GameConfig.Time.DAWN_START || adjustedTime > GameConfig.Time.NIGHT_START;
  }
  
  /**
   * Gets the current light level based on time of day.
   */
  float getLightLevel() {
    float adjustedTime = getAdjustedTime();
    TimePeriod period = getCurrentPeriod();
    
    switch (period) {
      case DAWN:
        return map(adjustedTime, GameConfig.Time.DAWN_START, GameConfig.Time.DAY_START, 0.3, 1.0);
      case DAY:
        return 1.0;
      case DUSK:
        return map(adjustedTime, GameConfig.Time.DUSK_START, GameConfig.Time.NIGHT_START, 1.0, 0.3);
      case NIGHT:
        return 0.3;
      default:
        return 1.0;
    }
  }
  
  /**
   * Sets the time scale (speed of time progression).
   */
  void setTimeScale(float scale) {
    timeScale = scale;
  }
  
  /**
   * Resets the time manager to initial state.
   */
  void reset() {
    timeOfDay = 0;
    initialTimeOfDay = random(1);
  }
}

/**
 * Represents different periods of the day.
 */
enum TimePeriod {
  DAWN,
  DAY,
  DUSK,
  NIGHT
} 