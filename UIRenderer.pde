/**
 * Handles rendering of UI elements.
 */
class UIRenderer {
  private final RenderConfig config;
  
  UIRenderer(RenderConfig config) {
    this.config = config;
  }
  
  /**
   * Draws the main UI elements.
   */
  void draw(GameState gameState, TimeManager timeManager) {
    // Draw time of day indicator
    drawTimeIndicator(timeManager.getAdjustedTime());
    
    // Draw game phase indicator
    drawPhaseIndicator(gameState.getPhase());
    
    // Draw score if game is over
    if (gameState.getPhase() == GamePhase.GAME_OVER) {
      drawGameOver(gameState);
    }
  }
  
  /**
   * Draws a preview of unit placement at the current mouse position.
   */
  void drawPlacementPreview(GameState gameState, GridManager grid, PVector gridPos, float lightLevel) {
    // Only show preview if position is valid
    if (gridPos != null && grid.isValidPosition((int)gridPos.x, (int)gridPos.y)) {
      pushMatrix();
      noFill();
      stroke(255, 255, 255, 128);
      strokeWeight(2);
      
      // Draw preview box
      float cellSize = GameConfig.World.WINDOW_SIZE / (float)GameConfig.World.SIZE;
      float x = mouseX - cellSize/2;
      float y = mouseY - cellSize/2;
      rect(x, y, cellSize, cellSize);
      
      // Draw unit preview
      color previewColor = color(
        GameConfig.VisualValues.PLAYER_A_RGB[0],
        GameConfig.VisualValues.PLAYER_A_RGB[1],
        GameConfig.VisualValues.PLAYER_A_RGB[2],
        128
      );
      fill(previewColor);
      noStroke();
      ellipse(mouseX, mouseY, cellSize * GameConfig.VisualValues.UNIT_SCALE, cellSize * GameConfig.VisualValues.UNIT_SCALE);
      
      popMatrix();
    }
  }
  
  /**
   * Shows debug information.
   */
  void showDebugInfo(int mouseX, int mouseY, PVector worldPos, PVector gridPos) {
    fill(255);
    textAlign(LEFT, TOP);
    textSize(12);
    text("Mouse: " + mouseX + ", " + mouseY, 10, 10);
    text("World: " + nf(worldPos.x, 0, 2) + ", " + nf(worldPos.y, 0, 2), 10, 25);
    text("Grid: " + nf(gridPos.x, 0, 2) + ", " + nf(gridPos.y, 0, 2), 10, 40);
  }
  
  /**
   * Draws the time of day indicator.
   */
  private void drawTimeIndicator(float adjustedTime) {
    float x = width - 110;
    float y = 20;
    float w = 100;
    float h = 20;
    
    // Draw background
    noStroke();
    fill(0, 128);
    rect(x, y, w, h);
    
    // Draw progress bar
    fill(255);
    rect(x, y, w * adjustedTime, h);
    
    // Draw time text
    fill(0);
    textAlign(CENTER, CENTER);
    textSize(12);
    text(nf(adjustedTime * 24, 0, 1) + ":00", x + w/2, y + h/2);
  }
  
  /**
   * Draws the current game phase indicator.
   */
  private void drawPhaseIndicator(GamePhase phase) {
    fill(0, 128);
    noStroke();
    rect(10, height - 30, 120, 20);
    
    fill(255);
    textAlign(LEFT, CENTER);
    textSize(12);
    text(phase.toString(), 15, height - 20);
  }
  
  /**
   * Draws the game over screen with final scores.
   */
  private void drawGameOver(GameState gameState) {
    // Draw semi-transparent overlay
    fill(0, 128);
    noStroke();
    rect(0, 0, width, height);
    
    // Draw "Game Over" text
    fill(255);
    textAlign(CENTER, CENTER);
    textSize(32);
    text("Game Over", width/2, height/2 - 40);
    
    // Draw territory percentages
    textSize(24);
    text("Player A Territory: " + nf(gameState.playerATerritoryPercent, 0, 1) + "%", width/2, height/2 + 10);
    text("Player B Territory: " + nf(gameState.playerBTerritoryPercent, 0, 1) + "%", width/2, height/2 + 40);
    
    // Draw winner
    textSize(28);
    String winner;
    if (gameState.playerAUnitCount > 0 && gameState.playerBUnitCount == 0) {
      winner = "Player A Wins!";
    } else if (gameState.playerBUnitCount > 0 && gameState.playerAUnitCount == 0) {
      winner = "Player B Wins!";
    } else {
      winner = "Draw!";
    }
    text(winner, width/2, height/2 - 80);
  }
} 