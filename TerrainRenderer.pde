/**
 * Handles the rendering of terrain features.
 */
class TerrainRenderer {
  private final RenderConfig config;
  
  TerrainRenderer(RenderConfig config) {
    this.config = config;
  }
  
  /**
   * Draws terrain for the entire world.
   */
  void draw(TerrainManager terrain) {
    float cellSize = GameConfig.World.WINDOW_SIZE / (float)GameConfig.World.SIZE;
    
    for (int y = 0; y < GameConfig.World.SIZE; y++) {
      for (int x = 0; x < GameConfig.World.SIZE; x++) {
        drawTerrainTile(x, y, cellSize, terrain);
      }
    }
  }
  
  /**
   * Draws a single terrain tile.
   */
  private void drawTerrainTile(int x, int y, float cellSize, TerrainManager terrain) {
    float noiseVal = getTerrainNoise(x, y, terrain);
    float height = noiseVal * cellSize * 0.25;
    color terrainColor = getTerrainColor(noiseVal, terrain);
    
    // Convert to isometric coordinates
    float isoX = (x - y) * cellSize * 0.5;
    float isoY = (x + y) * cellSize * 0.25;
    
    noStroke();
    fill(terrainColor);
    
    // Draw tile
    beginShape();
    vertex(isoX, isoY - height);
    vertex(isoX + cellSize * 0.5, isoY + cellSize * 0.25 - height);
    vertex(isoX, isoY + cellSize * 0.5 - height);
    vertex(isoX - cellSize * 0.5, isoY + cellSize * 0.25 - height);
    endShape(CLOSE);
  }
  
  /**
   * Gets the terrain height at a specific grid position.
   */
  float getTerrainHeight(int x, int y, TerrainManager terrain) {
    float cellSize = GameConfig.World.WINDOW_SIZE / (float)GameConfig.World.SIZE;
    float noiseVal = getTerrainNoise(x, y, terrain);
    return noiseVal * cellSize * 0.25;
  }
  
  /**
   * Gets the terrain noise value at a specific grid position.
   */
  float getTerrainNoise(int x, int y, TerrainManager terrain) {
    return noise(x * GameConfig.Terrain.NOISE_SCALE + terrain.getRawHeight(x, y),
                y * GameConfig.Terrain.NOISE_SCALE + terrain.getRawHeight(x, y));
  }
  
  /**
   * Gets the terrain color based on height.
   */
  private color getTerrainColor(float noiseVal, TerrainManager terrain) {
    if (noiseVal < GameConfig.Terrain.WATER_LEVEL) return terrain.terrainColors[TerrainType.WATER.ordinal()];
    if (noiseVal < GameConfig.Terrain.SAND_LEVEL) return terrain.terrainColors[TerrainType.SAND.ordinal()];
    if (noiseVal < GameConfig.Terrain.DIRT_LEVEL) return terrain.terrainColors[TerrainType.DIRT.ordinal()];
    if (noiseVal < GameConfig.Terrain.GRASS_LIGHT_LEVEL) return terrain.terrainColors[TerrainType.GRASS_LIGHT.ordinal()];
    if (noiseVal < GameConfig.Terrain.GRASS_DARK_LEVEL) return terrain.terrainColors[TerrainType.GRASS_DARK.ordinal()];
    return terrain.terrainColors[TerrainType.STONE.ordinal()];
  }
} 