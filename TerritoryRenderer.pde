/**
 * Handles the rendering of territory control and influence.
 */
class TerritoryRenderer {
  private final RenderConfig config;
  private final TerrainManager terrainManager;
  private final CameraManager cameraManager;
  
  TerritoryRenderer(RenderConfig config, TerrainManager terrainManager, CameraManager cameraManager) {
    this.config = config;
    this.terrainManager = terrainManager;
    this.cameraManager = cameraManager;
  }
  
  /**
   * Draws all territory-related visuals.
   */
  void draw(GridManager grid) {
    float cellSize = GameConfig.World.WINDOW_SIZE / (float)GameConfig.World.SIZE;
    
    // Draw territory fills first
    drawTerritoryFills(grid, cellSize);
    
    // Then draw territory boundaries
    drawTerritoryBorders(grid, cellSize);
  }
  
  /**
   * Draws the filled areas of territories.
   */
  private void drawTerritoryFills(GridManager grid, float cellSize) {
    // Draw base territories first
    color playerAColor = color(GameConfig.VisualValues.PLAYER_A_RGB[0], 
                             GameConfig.VisualValues.PLAYER_A_RGB[1], 
                             GameConfig.VisualValues.PLAYER_A_RGB[2]);
    color playerBColor = color(GameConfig.VisualValues.PLAYER_B_RGB[0], 
                             GameConfig.VisualValues.PLAYER_B_RGB[1], 
                             GameConfig.VisualValues.PLAYER_B_RGB[2]);
    color sharedColor = color(GameConfig.VisualValues.SHARED_RGB[0], 
                            GameConfig.VisualValues.SHARED_RGB[1], 
                            GameConfig.VisualValues.SHARED_RGB[2]);
                            
    drawPlayerTerritoryFill(grid.territoryGridA, playerAColor, cellSize);
    drawPlayerTerritoryFill(grid.territoryGridB, playerBColor, cellSize);
    
    // Draw contested territories on top
    drawContestedTerritoryFill(grid, cellSize, sharedColor);
  }
  
  /**
   * Draws territory borders.
   */
  private void drawTerritoryBorders(GridManager grid, float cellSize) {
    strokeWeight(2 / cameraManager.getZoom());
    
    color playerAColor = color(GameConfig.VisualValues.PLAYER_A_RGB[0], 
                             GameConfig.VisualValues.PLAYER_A_RGB[1], 
                             GameConfig.VisualValues.PLAYER_A_RGB[2]);
    color playerBColor = color(GameConfig.VisualValues.PLAYER_B_RGB[0], 
                             GameConfig.VisualValues.PLAYER_B_RGB[1], 
                             GameConfig.VisualValues.PLAYER_B_RGB[2]);
    color sharedColor = color(GameConfig.VisualValues.SHARED_RGB[0], 
                            GameConfig.VisualValues.SHARED_RGB[1], 
                            GameConfig.VisualValues.SHARED_RGB[2]);
    
    drawPlayerTerritoryBorders(grid.territoryGridA, playerAColor, cellSize);
    drawPlayerTerritoryBorders(grid.territoryGridB, playerBColor, cellSize);
    drawContestedTerritoryBorders(grid, cellSize, sharedColor);
  }
  
  /**
   * Draws the filled area for a single player's territory.
   */
  private void drawPlayerTerritoryFill(float[][] territoryGrid, color playerColor, float cellSize) {
    noStroke();
    
    for (int y = 0; y < GameConfig.World.SIZE; y++) {
      for (int x = 0; x < GameConfig.World.SIZE; x++) {
        if (territoryGrid[x][y] > 0) {
          float strength = min(1.0, territoryGrid[x][y] / 2.0);
          color territoryColor = color(
            red(playerColor),
            green(playerColor),
            blue(playerColor),
            GameConfig.VisualValues.TERRITORY_BASE_ALPHA * strength
          );
          drawTerritoryTile(x, y, cellSize, territoryColor);
        }
      }
    }
  }
  
  /**
   * Draws the filled areas for contested territory.
   */
  private void drawContestedTerritoryFill(GridManager grid, float cellSize, color sharedColor) {
    noStroke();
    
    for (int y = 0; y < GameConfig.World.SIZE; y++) {
      for (int x = 0; x < GameConfig.World.SIZE; x++) {
        if (grid.territoryGridA[x][y] > 0 && grid.territoryGridB[x][y] > 0) {
          float contestStrength = min(
            grid.territoryGridA[x][y],
            grid.territoryGridB[x][y]
          ) / 2.0;
          
          color contestedColor = color(
            red(sharedColor),
            green(sharedColor),
            blue(sharedColor),
            GameConfig.VisualValues.TERRITORY_CONTESTED_ALPHA * contestStrength
          );
          drawTerritoryTile(x, y, cellSize, contestedColor);
        }
      }
    }
  }
  
  /**
   * Draws a single territory tile.
   */
  private void drawTerritoryTile(int x, int y, float cellSize, color tileColor) {
    float isoX = (x - y) * cellSize * 0.5;
    float isoY = (x + y) * cellSize * 0.25;
    float height = terrainManager.getTerrainHeight(x, y);
    
    if (tileColor != 0) fill(tileColor);
    
    beginShape();
    vertex(isoX, isoY - height);
    vertex(isoX + cellSize * 0.5, isoY + cellSize * 0.25 - height);
    vertex(isoX, isoY + cellSize * 0.5 - height);
    vertex(isoX - cellSize * 0.5, isoY + cellSize * 0.25 - height);
    endShape(CLOSE);
  }
  
  /**
   * Draws borders for a single player's territory.
   */
  private void drawPlayerTerritoryBorders(float[][] territoryGrid, color playerColor, float cellSize) {
    stroke(red(playerColor), green(playerColor), blue(playerColor), 
           GameConfig.VisualValues.TERRITORY_BORDER_ALPHA);
    noFill();
    
    for (int y = 0; y < GameConfig.World.SIZE; y++) {
      for (int x = 0; x < GameConfig.World.SIZE; x++) {
        if (territoryGrid[x][y] > 0 && isBorderCell(x, y, territoryGrid)) {
          drawTerritoryTile(x, y, cellSize, 0);
        }
      }
    }
  }
  
  /**
   * Draws borders for contested territory.
   */
  private void drawContestedTerritoryBorders(GridManager grid, float cellSize, color sharedColor) {
    stroke(red(sharedColor), green(sharedColor), blue(sharedColor), 
           GameConfig.VisualValues.TERRITORY_BORDER_ALPHA);
    noFill();
    
    for (int y = 0; y < GameConfig.World.SIZE; y++) {
      for (int x = 0; x < GameConfig.World.SIZE; x++) {
        if (grid.territoryGridA[x][y] > 0 && grid.territoryGridB[x][y] > 0 && 
            isContestedBorderCell(x, y, grid)) {
          drawTerritoryTile(x, y, cellSize, 0);
        }
      }
    }
  }
  
  /**
   * Checks if a cell is on the border of a territory.
   */
  private boolean isBorderCell(int x, int y, float[][] territoryGrid) {
    for (int dx = -1; dx <= 1; dx++) {
      for (int dy = -1; dy <= 1; dy++) {
        if (dx == 0 && dy == 0) continue;
        int nx = x + dx;
        int ny = y + dy;
        if (!isValidPosition(nx, ny) || territoryGrid[nx][ny] <= 0) {
          return true;
        }
      }
    }
    return false;
  }
  
  /**
   * Checks if a cell is on the border of contested territory.
   */
  private boolean isContestedBorderCell(int x, int y, GridManager grid) {
    for (int dx = -1; dx <= 1; dx++) {
      for (int dy = -1; dy <= 1; dy++) {
        if (dx == 0 && dy == 0) continue;
        int nx = x + dx;
        int ny = y + dy;
        if (!isValidPosition(nx, ny) || 
            !(grid.territoryGridA[nx][ny] > 0 && grid.territoryGridB[nx][ny] > 0)) {
          return true;
        }
      }
    }
    return false;
  }
  
  /**
   * Checks if a position is valid on the grid.
   */
  private boolean isValidPosition(int x, int y) {
    return x >= 0 && x < GameConfig.World.SIZE && 
           y >= 0 && y < GameConfig.World.SIZE;
  }
} 