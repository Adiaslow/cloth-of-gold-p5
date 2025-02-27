/**
 * Centralizes all game configuration and constants.
 * Follows Interface Segregation Principle by grouping related constants.
 */
static class GameConfig {
  // World configuration
  static class World {
    static final int SIZE = 100;
    static final int WINDOW_SIZE = 800;
    static final float CELL_SIZE = WINDOW_SIZE / (float)SIZE;
  }
  
  // Game rules
  static class Rules {
    static final int SIMULATION_GENERATIONS = 100;
    static final int MAX_UNITS_PER_TURN = 10;
    static final float PLACEMENT_RADIUS = 1.0f;
    static final float TERRITORY_RADIUS = 8.0f;
    static final float MIN_TERRITORY_RADIUS = 4.0f;
    static final float TERRITORY_INFLUENCE_THRESHOLD = 0.5f;
  }
  
  // Resource configuration
  static class Resources {
    static final int STARTING_RESOURCES = 100;
    static final int UNIT_COST = 10;
    static final int TERRITORY_INCOME = 1;
    static final int RESOURCE_CAP = 1000;
  }
  
  // Terrain configuration
  static class Terrain {
    static final float WATER_LEVEL = 0.3f;
    static final float SAND_LEVEL = 0.35f;
    static final float DIRT_LEVEL = 0.5f;
    static final float GRASS_LIGHT_LEVEL = 0.7f;
    static final float GRASS_DARK_LEVEL = 0.8f;
    
    static final float NOISE_SCALE = 0.05f;
    static final float HEIGHT_SCALE = 0.25f;
  }
  
  // Visual configuration values
  static class VisualValues {
    // Player colors (RGB values)
    static final int[] PLAYER_A_RGB = {255, 255, 255};  // White
    static final int[] PLAYER_B_RGB = {0, 0, 0};        // Black
    static final int[] SHARED_RGB = {255, 0, 0};        // Red
    static final int[] NEUTRAL_RGB = {255, 140, 0};     // Orange
    static final int[] DEAD_RGB = {128, 0, 128};        // Purple
    
    // Sky colors (RGB values)
    static final int[] SKY_DAWN_RGB = {255, 200, 150};
    static final int SKY_DAY_VALUE = 220;
    static final int[] SKY_DUSK_RGB = {255, 140, 100};
    static final int SKY_NIGHT_VALUE = 20;
    
    // UI configuration
    static final float UI_PADDING = 10;
    static final float UI_ALPHA = 200;
    static final float UI_CORNER_RADIUS = 5;
    
    // Unit visualization
    static final float UNIT_SCALE = 0.6f;
    static final float TERRITORY_BASE_ALPHA = 30;
    static final float TERRITORY_CONTESTED_ALPHA = 40;
    static final float TERRITORY_BORDER_ALPHA = 128;
  }
  
  // Camera configuration
  static class Camera {
    static final float DEFAULT_ZOOM = 1.0f;
    static final float MIN_ZOOM = 0.01f;
    static final float MAX_ZOOM = 1.0f;
    static final float ZOOM_SPEED = 0.1f;
  }
  
  // Time configuration
  static class Time {
    static final float DAY_LENGTH = 1.0f;
    static final float DAWN_START = 0.0f;
    static final float DAY_START = 0.25f;
    static final float DUSK_START = 0.75f;
    static final float NIGHT_START = 0.85f;
    static final float DEFAULT_TIME_SCALE = 0.001f;
  }
}

/**
 * Provides type-safe access to terrain types.
 */
enum TerrainType {
  WATER,
  SAND,
  DIRT,
  GRASS_LIGHT,
  GRASS_DARK,
  STONE
}

/**
 * Provides type-safe access to player types.
 */
enum PlayerType {
  NONE('0'),
  PLAYER_A('A'),
  PLAYER_B('B'),
  NEUTRAL('N'),
  DEAD('D');
  
  private final char value;
  
  private PlayerType(char value) {
    this.value = value;
  }
  
  public char getValue() {
    return value;
  }
  
  public static PlayerType fromValue(char value) {
    for (PlayerType type : values()) {
      if (type.value == value) return type;
    }
    return NONE;
  }
}

/**
 * Class that handles color creation using Processing's color function.
 * This must be non-static since it uses Processing functions.
 */
class Visual {
  color PLAYER_A_COLOR;
  color PLAYER_B_COLOR;
  color SHARED_COLOR;
  color NEUTRAL_COLOR;
  color DEAD_COLOR;
  
  color SKY_DAWN;
  color SKY_DAY;
  color SKY_DUSK;
  color SKY_NIGHT;
  
  Visual() {
    // Initialize player colors
    PLAYER_A_COLOR = color(GameConfig.VisualValues.PLAYER_A_RGB[0], 
                          GameConfig.VisualValues.PLAYER_A_RGB[1], 
                          GameConfig.VisualValues.PLAYER_A_RGB[2]);
    
    PLAYER_B_COLOR = color(GameConfig.VisualValues.PLAYER_B_RGB[0], 
                          GameConfig.VisualValues.PLAYER_B_RGB[1], 
                          GameConfig.VisualValues.PLAYER_B_RGB[2]);
    
    SHARED_COLOR = color(GameConfig.VisualValues.SHARED_RGB[0], 
                        GameConfig.VisualValues.SHARED_RGB[1], 
                        GameConfig.VisualValues.SHARED_RGB[2]);
    
    NEUTRAL_COLOR = color(GameConfig.VisualValues.NEUTRAL_RGB[0], 
                         GameConfig.VisualValues.NEUTRAL_RGB[1], 
                         GameConfig.VisualValues.NEUTRAL_RGB[2]);
    
    DEAD_COLOR = color(GameConfig.VisualValues.DEAD_RGB[0], 
                      GameConfig.VisualValues.DEAD_RGB[1], 
                      GameConfig.VisualValues.DEAD_RGB[2]);
    
    // Initialize sky colors
    SKY_DAWN = color(GameConfig.VisualValues.SKY_DAWN_RGB[0], 
                     GameConfig.VisualValues.SKY_DAWN_RGB[1], 
                     GameConfig.VisualValues.SKY_DAWN_RGB[2]);
    
    SKY_DAY = color(GameConfig.VisualValues.SKY_DAY_VALUE);
    
    SKY_DUSK = color(GameConfig.VisualValues.SKY_DUSK_RGB[0], 
                     GameConfig.VisualValues.SKY_DUSK_RGB[1], 
                     GameConfig.VisualValues.SKY_DUSK_RGB[2]);
    
    SKY_NIGHT = color(GameConfig.VisualValues.SKY_NIGHT_VALUE);
  }
} 