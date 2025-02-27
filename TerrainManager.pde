/**
 * Manages terrain generation and terrain-related queries.
 * Follows Single Responsibility Principle by focusing on terrain management.
 */
class TerrainManager {
  private float[][] heightMap;
  private TerrainType[][] terrainTypes;
  private final color[] terrainColors;
  
  TerrainManager() {
    heightMap = new float[GameConfig.World.SIZE][GameConfig.World.SIZE];
    terrainTypes = new TerrainType[GameConfig.World.SIZE][GameConfig.World.SIZE];
    terrainColors = initializeTerrainColors();
    generateTerrain();
  }
  
  /**
   * Initializes the terrain color palette.
   */
  private color[] initializeTerrainColors() {
    color[] colors = new color[TerrainType.values().length];
    colors[TerrainType.WATER.ordinal()] = color(64, 164, 223);     // Blue water
    colors[TerrainType.SAND.ordinal()] = color(238, 214, 175);     // Sandy beach
    colors[TerrainType.DIRT.ordinal()] = color(139, 119, 101);     // Brown dirt
    colors[TerrainType.GRASS_LIGHT.ordinal()] = color(124, 168, 92); // Light grass
    colors[TerrainType.GRASS_DARK.ordinal()] = color(84, 128, 52);   // Dark grass
    colors[TerrainType.STONE.ordinal()] = color(128, 128, 128);    // Gray stone
    return colors;
  }
  
  /**
   * Generates the terrain using Perlin noise.
   */
  void generateTerrain() {
    float noiseOffset = random(1000);  // Random offset for variety
    
    for (int y = 0; y < GameConfig.World.SIZE; y++) {
      for (int x = 0; x < GameConfig.World.SIZE; x++) {
        float noiseValue = noise(
          x * GameConfig.Terrain.NOISE_SCALE + noiseOffset,
          y * GameConfig.Terrain.NOISE_SCALE + noiseOffset
        );
        heightMap[x][y] = noiseValue;
        terrainTypes[x][y] = determineTerrainType(noiseValue);
      }
    }
  }
  
  /**
   * Determines terrain type based on height value.
   */
  private TerrainType determineTerrainType(float height) {
    if (height < GameConfig.Terrain.WATER_LEVEL) return TerrainType.WATER;
    if (height < GameConfig.Terrain.SAND_LEVEL) return TerrainType.SAND;
    if (height < GameConfig.Terrain.DIRT_LEVEL) return TerrainType.DIRT;
    if (height < GameConfig.Terrain.GRASS_LIGHT_LEVEL) return TerrainType.GRASS_LIGHT;
    if (height < GameConfig.Terrain.GRASS_DARK_LEVEL) return TerrainType.GRASS_DARK;
    return TerrainType.STONE;
  }
  
  /**
   * Gets the terrain type at a specific position.
   */
  TerrainType getTerrainType(int x, int y) {
    if (!isValidPosition(x, y)) return TerrainType.WATER;
    return terrainTypes[x][y];
  }
  
  /**
   * Gets the terrain height at a specific position.
   */
  float getTerrainHeight(int x, int y) {
    if (!isValidPosition(x, y)) return 0;
    return heightMap[x][y] * GameConfig.Terrain.HEIGHT_SCALE;
  }
  
  /**
   * Gets the terrain color for a specific terrain type.
   */
  color getTerrainColor(TerrainType type) {
    return terrainColors[type.ordinal()];
  }
  
  /**
   * Gets the terrain color at a specific position.
   */
  color getTerrainColorAt(int x, int y) {
    return getTerrainColor(getTerrainType(x, y));
  }
  
  /**
   * Checks if a position is valid on the terrain.
   */
  private boolean isValidPosition(int x, int y) {
    return x >= 0 && x < GameConfig.World.SIZE && 
           y >= 0 && y < GameConfig.World.SIZE;
  }
  
  /**
   * Checks if a position is walkable (not water).
   */
  boolean isWalkable(int x, int y) {
    return getTerrainType(x, y) != TerrainType.WATER;
  }
  
  /**
   * Gets the raw height map value at a position.
   */
  float getRawHeight(int x, int y) {
    if (!isValidPosition(x, y)) return 0;
    return heightMap[x][y];
  }
} 