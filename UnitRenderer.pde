/**
 * Handles the rendering of game units.
 */
class UnitRenderer {
  private final RenderConfig config;
  private final TerrainManager terrainManager;
  
  UnitRenderer(RenderConfig config, TerrainManager terrainManager) {
    this.config = config;
    this.terrainManager = terrainManager;
  }
  
  /**
   * Draws all units on the grid with lighting effects.
   */
  void draw(GridManager grid, float lightLevel) {
    float cellSize = GameConfig.World.WINDOW_SIZE / (float)GameConfig.World.SIZE;
    
    // Draw units for both players
    drawPlayerUnits(grid.unitGridA, GameConfig.VisualValues.PLAYER_A_RGB, cellSize, lightLevel);
    drawPlayerUnits(grid.unitGridB, GameConfig.VisualValues.PLAYER_B_RGB, cellSize, lightLevel);
  }
  
  /**
   * Draws units for a specific player.
   */
  private void drawPlayerUnits(Unit[][] unitGrid, int[] playerRGB, float cellSize, float lightLevel) {
    for (int y = 0; y < GameConfig.World.SIZE; y++) {
      for (int x = 0; x < GameConfig.World.SIZE; x++) {
        Unit unit = unitGrid[x][y];
        if (unit != null && unit.isAlive()) {
          drawUnit(x, y, unit, color(playerRGB[0], playerRGB[1], playerRGB[2]), cellSize, lightLevel);
        }
      }
    }
  }
  
  /**
   * Draws a single unit.
   */
  private void drawUnit(int x, int y, Unit unit, color playerColor, float cellSize, float lightLevel) {
    float isoX = (x - y) * cellSize * 0.5;
    float isoY = (x + y) * cellSize * 0.25;
    float height = terrainManager.getTerrainHeight(x, y);
    
    // Apply lighting to unit color
    color adjustedColor = color(
      red(playerColor) * lightLevel,
      green(playerColor) * lightLevel,
      blue(playerColor) * lightLevel,
      alpha(playerColor)
    );
    
    // Draw unit body
    noStroke();
    fill(adjustedColor);
    float unitSize = cellSize * GameConfig.VisualValues.UNIT_SCALE;
    
    pushMatrix();
    translate(isoX, isoY - height - unitSize * 0.5);
    
    // Draw based on unit type
    switch (unit.getType()) {
      case WARRIOR:
        drawWarrior(unitSize);
        break;
      case ARCHER:
        drawArcher(unitSize);
        break;
      case CAVALRY:
        drawCavalry(unitSize);
        break;
    }
    
    popMatrix();
  }
  
  /**
   * Draws a warrior unit.
   */
  private void drawWarrior(float size) {
    // Draw warrior as a pentagon
    beginShape();
    vertex(0, -size * 0.5);
    vertex(size * 0.3, -size * 0.2);
    vertex(size * 0.2, size * 0.5);
    vertex(-size * 0.2, size * 0.5);
    vertex(-size * 0.3, -size * 0.2);
    endShape(CLOSE);
  }
  
  /**
   * Draws an archer unit.
   */
  private void drawArcher(float size) {
    // Draw archer as a triangle
    beginShape();
    vertex(0, -size * 0.5);
    vertex(size * 0.4, size * 0.5);
    vertex(-size * 0.4, size * 0.5);
    endShape(CLOSE);
  }
  
  /**
   * Draws a cavalry unit.
   */
  private void drawCavalry(float size) {
    // Draw cavalry as a diamond
    beginShape();
    vertex(0, -size * 0.5);
    vertex(size * 0.4, 0);
    vertex(0, size * 0.5);
    vertex(-size * 0.4, 0);
    endShape(CLOSE);
  }
} 